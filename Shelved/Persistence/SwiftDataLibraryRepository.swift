import Foundation
import SwiftData

/// `LibraryRepository` backed by SwiftData.
///
/// The only file that turns `@Model` objects into domain values and back.
/// Methods are synchronous: they satisfy the protocol's `async` requirements
/// (a sync function can always stand in for an async one), and the main
/// context does its work on the main thread anyway.
@MainActor
final class SwiftDataLibraryRepository: LibraryRepository {
    /// The app's on-disk library. Phase 5 replaces this global with a
    /// `Dependencies` container built at launch.
    static let shared = makeShared()

    private let container: ModelContainer
    private let context: ModelContext
    private let now: () -> Date

    /// - Parameter now: injectable so tests can check automatic dates exactly.
    init(container: ModelContainer, now: @escaping () -> Date = { .now }) throws {
        self.container = container
        self.context = container.mainContext
        self.now = now
        try ensureSystemShelves()
    }

    /// A throwaway store for tests and previews.
    static func inMemory(now: @escaping () -> Date = { .now }) throws -> SwiftDataLibraryRepository {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Shelf.self, LibraryEntry.self, configurations: configuration)
        return try SwiftDataLibraryRepository(container: container, now: now)
    }

    private static func makeShared() -> SwiftDataLibraryRepository {
        do {
            let container = try ModelContainer(for: Shelf.self, LibraryEntry.self)
            return try SwiftDataLibraryRepository(container: container)
        } catch {
            // The on-disk store wouldn't open, most likely a model change
            // without a migration. Crash loudly in debug builds; in release,
            // run with an empty in-memory library rather than not at all.
            assertionFailure("Couldn't open the library store: \(error)")
            do {
                return try inMemory()
            } catch {
                fatalError("Couldn't create even an in-memory library: \(error)")
            }
        }
    }

    // MARK: - Reads

    func shelves() throws -> [ShelfSummary] {
        let descriptor = FetchDescriptor<Shelf>(sortBy: [SortDescriptor(\.sortOrder)])
        return try context.fetch(descriptor).map(Self.summary(from:))
    }

    func items(on shelfID: ShelfID) throws -> [LibraryItem] {
        let shelf = try fetchShelf(shelfID)
        return (shelf.entries ?? [])
            .sorted { $0.addedAt > $1.addedAt }
            .compactMap(Self.item(from:))
    }

    func item(for id: MediaID) throws -> LibraryItem? {
        try fetchEntry(id).flatMap(Self.item(from:))
    }

    // MARK: - Writes

    @discardableResult
    func save(_ media: MediaItem, to shelfID: ShelfID) throws -> LibraryItem {
        let shelf = try fetchShelf(shelfID)

        let entry: LibraryEntry
        if let existing = try fetchEntry(media.id) {
            entry = existing
        } else {
            entry = LibraryEntry(mediaKey: media.id.storageKey)
            entry.addedAt = now()
            context.insert(entry)
        }

        // Refresh the snapshot every time: the title or cover may have
        // been corrected on Open Library since it was first saved.
        entry.kindRaw = media.kind.rawValue
        entry.title = media.title
        entry.creatorKeys = media.creators.map(\.id.storageKey)
        entry.creatorNames = media.creators.map(\.name)
        entry.coverURL = media.coverURL
        entry.year = media.year

        entry.shelf = shelf
        let system = shelf.systemKind.flatMap(SystemShelf.init(rawValue:))
        Self.apply(Self.log(from: entry).movedTo(system, at: now()), to: entry)

        try context.save()
        guard let item = Self.item(from: entry) else { throw LibraryError.itemNotFound }
        return item
    }

    func remove(_ id: MediaID) throws {
        guard let entry = try fetchEntry(id) else { return }
        context.delete(entry)
        try context.save()
    }

    func updateLog(_ log: ReadingLog, for id: MediaID) throws {
        guard let entry = try fetchEntry(id) else { throw LibraryError.itemNotFound }
        Self.apply(log, to: entry)
        try context.save()
    }

    func createShelf(named rawName: String) throws -> ShelfSummary {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw LibraryError.emptyShelfName }

        let existing = try shelves()
        // Compare against display names, so "finished" clashes with the built-in "Finished".
        guard !existing.contains(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            throw LibraryError.duplicateShelfName
        }

        let nextOrder = (try context.fetch(FetchDescriptor<Shelf>()).map(\.sortOrder).max() ?? -1) + 1
        let shelf = Shelf(name: name, system: nil, sortOrder: nextOrder)
        context.insert(shelf)
        try context.save()
        return Self.summary(from: shelf)
    }

    func deleteShelf(_ id: ShelfID) throws {
        let shelf = try fetchShelf(id)
        guard shelf.systemKind == nil else { throw LibraryError.cannotDeleteSystemShelf }

        let wantTo = try fetchSystemShelf(.wantTo)
        for entry in shelf.entries ?? [] {
            entry.shelf = wantTo
        }
        context.delete(shelf)
        try context.save()
    }

    // MARK: - Helpers

    /// Creates any missing built-in shelves. Safe to run on every launch:
    /// it only inserts what isn't there, so it also covers a shelf added in
    /// a future version.
    private func ensureSystemShelves() throws {
        let present = Set(try context.fetch(FetchDescriptor<Shelf>()).compactMap(\.systemKind))
        var inserted = false
        for (index, system) in SystemShelf.allCases.enumerated() where !present.contains(system.rawValue) {
            context.insert(Shelf(name: "", system: system, sortOrder: index))
            inserted = true
        }
        if inserted { try context.save() }
    }

    private func fetchShelf(_ id: ShelfID) throws -> Shelf {
        // #Predicate can't reach into `id.rawValue`; copy it to a local first.
        let uuid = id.rawValue
        var descriptor = FetchDescriptor<Shelf>(predicate: #Predicate { $0.shelfID == uuid })
        descriptor.fetchLimit = 1
        guard let shelf = try context.fetch(descriptor).first else { throw LibraryError.shelfNotFound }
        return shelf
    }

    private func fetchSystemShelf(_ system: SystemShelf) throws -> Shelf {
        // Four rows at most, so filtering in memory is simpler than an
        // optional-String predicate.
        guard let shelf = try context.fetch(FetchDescriptor<Shelf>())
            .first(where: { $0.systemKind == system.rawValue })
        else { throw LibraryError.shelfNotFound }
        return shelf
    }

    private func fetchEntry(_ id: MediaID) throws -> LibraryEntry? {
        let key = id.storageKey
        var descriptor = FetchDescriptor<LibraryEntry>(predicate: #Predicate { $0.mediaKey == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Mapping (@Model ↔ domain)

    private static func summary(from shelf: Shelf) -> ShelfSummary {
        let system = shelf.systemKind.flatMap(SystemShelf.init(rawValue:))
        return ShelfSummary(
            id: ShelfID(rawValue: shelf.shelfID),
            name: system?.name ?? shelf.name,
            system: system,
            itemCount: shelf.entries?.count ?? 0
        )
    }

    /// nil for rows we can't show: an unknown ID format (e.g. written by a
    /// newer app version) or an entry that somehow lost its shelf.
    private static func item(from entry: LibraryEntry) -> LibraryItem? {
        guard let id = MediaID(storageKey: entry.mediaKey), let shelf = entry.shelf else { return nil }

        let creators = zip(entry.creatorKeys, entry.creatorNames).compactMap { key, name in
            CreatorID(storageKey: key).map { CreatorSummary(id: $0, name: name) }
        }
        let media = MediaItem(
            id: id,
            kind: MediaKind(rawValue: entry.kindRaw) ?? .book,
            title: entry.title,
            creators: creators,
            coverURL: entry.coverURL,
            year: entry.year
        )
        let shelfSummary = summary(from: shelf)
        return LibraryItem(
            media: media,
            shelfID: shelfSummary.id,
            shelfName: shelfSummary.name,
            log: log(from: entry),
            addedAt: entry.addedAt
        )
    }

    private static func log(from entry: LibraryEntry) -> ReadingLog {
        ReadingLog(
            rating: entry.ratingHalfStars.flatMap(Rating.init(halfStars:)),
            review: entry.review ?? "",
            progress: entry.progress,
            progressTotal: entry.progressTotal,
            startedAt: entry.startedAt,
            finishedAt: entry.finishedAt
        )
    }

    private static func apply(_ log: ReadingLog, to entry: LibraryEntry) {
        let review = log.review.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.ratingHalfStars = log.rating?.halfStars
        entry.review = review.isEmpty ? nil : review
        entry.progress = log.progress
        entry.progressTotal = log.progressTotal
        entry.startedAt = log.startedAt
        entry.finishedAt = log.finishedAt
    }
}
