import Foundation
import SwiftData
import Testing
@testable import Shelved

/// Runs the real SwiftData repository against an in-memory store.
///
/// Not a fake: this is the actual persistence code, so the tests catch
/// mapping and relationship bugs a fake would hide. In-memory keeps each
/// test isolated and fast.
@MainActor
struct SwiftDataLibraryRepositoryTests {
    private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)

    private let dune = MediaItem(
        id: .openLibraryWork("OL893414W"), kind: .book, title: "Dune",
        creators: [CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")],
        coverURL: URL(string: "https://covers.openlibrary.org/b/id/1-M.jpg"), year: 1965
    )

    private func makeRepository() throws -> SwiftDataLibraryRepository {
        let now = fixedNow
        return try SwiftDataLibraryRepository.inMemory(now: { now })
    }

    private func shelf(_ system: SystemShelf, in repository: SwiftDataLibraryRepository) throws -> ShelfSummary {
        try #require(try repository.shelves().first { $0.system == system })
    }

    @Test func seedsSystemShelvesInOrder() throws {
        let repository = try makeRepository()
        #expect(try repository.shelves().compactMap(\.system) == SystemShelf.allCases)
    }

    @Test func savedItemRoundTripsThroughStore() throws {
        let repository = try makeRepository()
        let wantTo = try shelf(.wantTo, in: repository)

        try repository.save(dune, to: wantTo.id)

        let saved = try #require(try repository.item(for: dune.id))
        #expect(saved.media == dune)   // the whole snapshot survives, creators included
        #expect(saved.shelfID == wantTo.id)
        #expect(try repository.items(on: wantTo.id).map(\.id) == [dune.id])
    }

    @Test func savingAgainMovesInsteadOfDuplicating() throws {
        let repository = try makeRepository()
        try repository.save(dune, to: shelf(.wantTo, in: repository).id)
        try repository.save(dune, to: shelf(.inProgress, in: repository).id)

        let counts = try repository.shelves().map(\.itemCount)
        #expect(counts == [0, 1, 0])
    }

    @Test func movingToInProgressAndFinishedSetsDates() throws {
        let repository = try makeRepository()
        try repository.save(dune, to: shelf(.inProgress, in: repository).id)
        #expect(try repository.item(for: dune.id)?.log.startedAt == fixedNow)

        try repository.save(dune, to: shelf(.finished, in: repository).id)
        #expect(try repository.item(for: dune.id)?.log.finishedAt == fixedNow)
    }

    @Test func updateLogPersistsAndTrimsEmptyReview() throws {
        let repository = try makeRepository()
        try repository.save(dune, to: shelf(.wantTo, in: repository).id)
        let log = ReadingLog(rating: Rating(stars: 4.5), review: "   ", progress: 10, progressTotal: 600)

        try repository.updateLog(log, for: dune.id)

        let saved = try #require(try repository.item(for: dune.id)).log
        #expect(saved.rating == Rating(stars: 4.5))
        #expect(saved.review.isEmpty)
        #expect(saved.progress == 10)
    }

    @Test func removeDeletesEntry() throws {
        let repository = try makeRepository()
        try repository.save(dune, to: shelf(.wantTo, in: repository).id)

        try repository.remove(dune.id)

        #expect(try repository.item(for: dune.id) == nil)
    }

    @Test func deletingCustomShelfMovesItemsToWantTo() throws {
        let repository = try makeRepository()
        let bookClub = try repository.createShelf(named: "Book Club")
        try repository.save(dune, to: bookClub.id)

        try repository.deleteShelf(bookClub.id)

        #expect(try repository.item(for: dune.id)?.shelfID == shelf(.wantTo, in: repository).id)
        #expect(try repository.shelves().count == SystemShelf.allCases.count)
    }

    /// Stores created before "Abandoned" was removed still have that row.
    @Test func removedSystemShelfKeepsItsItemsAsCustomShelf() throws {
        let container = try ModelContainer(
            for: Shelf.self, LibraryEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let legacy = Shelf(name: "", system: nil, sortOrder: 3)
        legacy.systemKind = "abandoned"
        container.mainContext.insert(legacy)
        let entry = LibraryEntry(mediaKey: dune.id.storageKey)
        entry.title = dune.title
        entry.shelf = legacy
        container.mainContext.insert(entry)
        try container.mainContext.save()

        let repository = try SwiftDataLibraryRepository(container: container)

        let custom = try #require(try repository.shelves().first { !$0.isSystem })
        #expect(custom.name == "Abandoned")
        #expect(try repository.item(for: dune.id)?.shelfID == custom.id)
    }

    @Test func emptyRemovedSystemShelfIsDeleted() throws {
        let container = try ModelContainer(
            for: Shelf.self, LibraryEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let legacy = Shelf(name: "", system: nil, sortOrder: 3)
        legacy.systemKind = "abandoned"
        container.mainContext.insert(legacy)
        try container.mainContext.save()

        let repository = try SwiftDataLibraryRepository(container: container)

        #expect(try repository.shelves().compactMap(\.system) == SystemShelf.allCases)
        #expect(try repository.shelves().count == SystemShelf.allCases.count)
    }

    @Test func systemShelvesCannotBeDeleted() throws {
        let repository = try makeRepository()
        let wantTo = try shelf(.wantTo, in: repository)
        #expect(throws: LibraryError.cannotDeleteSystemShelf) {
            try repository.deleteShelf(wantTo.id)
        }
    }

    @Test func shelfNamesMustBeUniqueAndNonEmpty() throws {
        let repository = try makeRepository()
        _ = try repository.createShelf(named: "Book Club")

        #expect(throws: LibraryError.duplicateShelfName) { try repository.createShelf(named: "book club") }
        #expect(throws: LibraryError.duplicateShelfName) { try repository.createShelf(named: "Finished") }
        #expect(throws: LibraryError.emptyShelfName) { try repository.createShelf(named: "   ") }
    }
}
