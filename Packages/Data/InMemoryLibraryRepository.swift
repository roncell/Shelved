import Core
import Foundation

/// A `LibraryRepository` that keeps everything in plain dictionaries.
///
/// A *fake*: a working implementation, just not a durable one. It exists
/// because of the module rules: feature previews need a library, but
/// features may not import Persistence (SwiftData). So the fake lives next
/// to the protocol, in Data.
///
/// It has to behave like the real one or previews lie. `LibraryRepositoryContractTests`
/// runs the same checks against both implementations to keep them in step.
@MainActor
public final class InMemoryLibraryRepository: LibraryRepository {
    private struct StoredShelf {
        let id: ShelfID
        var name: String
        let system: SystemShelf?
        let sortOrder: Int
    }

    private struct Entry {
        var media: MediaItem
        var shelfID: ShelfID
        var log: ReadingLog
        let addedAt: Date
    }

    private var storedShelves: [StoredShelf]
    private var entries: [MediaID: Entry] = [:]
    private let now: () -> Date

    public init(now: @escaping () -> Date = { .now }) {
        self.now = now
        storedShelves = SystemShelf.allCases.enumerated().map { index, system in
            StoredShelf(id: ShelfID(rawValue: UUID()), name: "", system: system, sortOrder: index)
        }
    }

    // MARK: - Reads

    public func shelves() throws -> [ShelfSummary] {
        storedShelves.sorted { $0.sortOrder < $1.sortOrder }.map(summary(of:))
    }

    public func items(on shelfID: ShelfID) throws -> [LibraryItem] {
        _ = try shelf(shelfID)
        return entries.values
            .filter { $0.shelfID == shelfID }
            .sorted { $0.addedAt > $1.addedAt }
            .compactMap(item(from:))
    }

    public func item(for id: MediaID) throws -> LibraryItem? {
        entries[id].flatMap(item(from:))
    }

    // MARK: - Writes

    @discardableResult
    public func save(_ media: MediaItem, to shelfID: ShelfID) throws -> LibraryItem {
        let shelf = try shelf(shelfID)
        var entry = entries[media.id] ?? Entry(media: media, shelfID: shelfID, log: ReadingLog(), addedAt: now())
        entry.media = media
        entry.shelfID = shelfID
        entry.log = entry.log.movedTo(shelf.system, at: now())
        entries[media.id] = entry
        guard let item = item(from: entry) else { throw LibraryError.itemNotFound }
        return item
    }

    public func remove(_ id: MediaID) throws {
        entries[id] = nil
    }

    public func updateLog(_ log: ReadingLog, for id: MediaID) throws {
        guard entries[id] != nil else { throw LibraryError.itemNotFound }
        var trimmed = log
        trimmed.review = log.review.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[id]?.log = trimmed
    }

    public func createShelf(named rawName: String) throws -> ShelfSummary {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw LibraryError.emptyShelfName }
        let takenNames = try shelves().map(\.name) + SystemShelf.allCases.flatMap(\.allNames)
        guard !takenNames.contains(where: { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            throw LibraryError.duplicateShelfName
        }
        let shelf = StoredShelf(
            id: ShelfID(rawValue: UUID()), name: name, system: nil,
            sortOrder: (storedShelves.map(\.sortOrder).max() ?? -1) + 1
        )
        storedShelves.append(shelf)
        return summary(of: shelf)
    }

    public func deleteShelf(_ id: ShelfID) throws {
        let shelf = try shelf(id)
        guard shelf.system == nil else { throw LibraryError.cannotDeleteSystemShelf }
        guard let wantTo = storedShelves.first(where: { $0.system == .wantTo }) else { throw LibraryError.shelfNotFound }
        for (mediaID, entry) in entries where entry.shelfID == id {
            entries[mediaID]?.shelfID = wantTo.id
        }
        storedShelves.removeAll { $0.id == id }
    }

    // MARK: - Helpers

    private func shelf(_ id: ShelfID) throws -> StoredShelf {
        guard let shelf = storedShelves.first(where: { $0.id == id }) else { throw LibraryError.shelfNotFound }
        return shelf
    }

    private func summary(of shelf: StoredShelf) -> ShelfSummary {
        ShelfSummary(
            id: shelf.id,
            name: shelf.system?.name ?? shelf.name,
            system: shelf.system,
            itemCount: entries.values.filter { $0.shelfID == shelf.id }.count
        )
    }

    private func item(from entry: Entry) -> LibraryItem? {
        guard let shelf = storedShelves.first(where: { $0.id == entry.shelfID }) else { return nil }
        let summary = summary(of: shelf)
        return LibraryItem(
            media: entry.media, shelfID: summary.id, shelfName: summary.name, log: entry.log, addedAt: entry.addedAt
        )
    }
}
