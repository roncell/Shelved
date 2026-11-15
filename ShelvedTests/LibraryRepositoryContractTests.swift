import Foundation
import Testing
@testable import Core
@testable import Data
@testable import Persistence

/// The behavior every `LibraryRepository` must have, run against each one.
///
/// Feature previews use `InMemoryLibraryRepository` because features can't
/// import SwiftData. A fake that drifts from the real thing makes previews
/// lie, so both run the same checks. Swift Testing's `arguments:` turns
/// each test into one case per implementation.
@MainActor
struct LibraryRepositoryContractTests {
    enum Implementation: String, CaseIterable, CustomTestStringConvertible {
        case swiftData, inMemory

        var testDescription: String { rawValue }

        @MainActor func make(now: Date) throws -> any LibraryRepository {
            switch self {
            case .swiftData: try SwiftDataLibraryRepository.inMemory(now: { now })
            case .inMemory: InMemoryLibraryRepository(now: { now })
            }
        }
    }

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let dune = PreviewCatalog.items[0]

    private func shelf(_ system: SystemShelf, in library: any LibraryRepository) async throws -> ShelfSummary {
        try #require(try await library.shelves().first { $0.system == system })
    }

    @Test(arguments: Implementation.allCases)
    func startsWithSystemShelvesInOrder(_ implementation: Implementation) async throws {
        let library = try implementation.make(now: now)
        #expect(try await library.shelves().compactMap(\.system) == SystemShelf.allCases)
    }

    @Test(arguments: Implementation.allCases)
    func savingMovesAndSetsDates(_ implementation: Implementation) async throws {
        let library = try implementation.make(now: now)
        try await library.save(dune, to: shelf(.wantTo, in: library).id)
        let saved = try await library.save(dune, to: shelf(.inProgress, in: library).id)

        #expect(saved.log.startedAt == now)
        #expect(try await library.shelves().map(\.itemCount) == [0, 1, 0])
        #expect(try await library.items(on: shelf(.inProgress, in: library).id).map(\.id) == [dune.id])
    }

    @Test(arguments: Implementation.allCases)
    func updateLogTrimsAndRemoveDeletes(_ implementation: Implementation) async throws {
        let library = try implementation.make(now: now)
        try await library.save(dune, to: shelf(.wantTo, in: library).id)

        try await library.updateLog(ReadingLog(rating: Rating(stars: 4), review: "  "), for: dune.id)
        #expect(try await library.item(for: dune.id)?.log == ReadingLog(rating: Rating(stars: 4)))

        try await library.remove(dune.id)
        #expect(try await library.item(for: dune.id) == nil)
        await #expect(throws: LibraryError.itemNotFound) {
            try await library.updateLog(ReadingLog(), for: dune.id)
        }
    }

    @Test(arguments: Implementation.allCases)
    func shelfNameRules(_ implementation: Implementation) async throws {
        let library = try implementation.make(now: now)
        _ = try await library.createShelf(named: "Book Club")

        await #expect(throws: LibraryError.duplicateShelfName) { try await library.createShelf(named: "book club") }
        await #expect(throws: LibraryError.duplicateShelfName) { try await library.createShelf(named: "Want to Watch") }
        await #expect(throws: LibraryError.emptyShelfName) { try await library.createShelf(named: " ") }
    }

    @Test(arguments: Implementation.allCases)
    func deletingCustomShelfKeepsItsItems(_ implementation: Implementation) async throws {
        let library = try implementation.make(now: now)
        let club = try await library.createShelf(named: "Book Club")
        try await library.save(dune, to: club.id)

        try await library.deleteShelf(club.id)

        #expect(try await library.item(for: dune.id)?.shelfID == shelf(.wantTo, in: library).id)
        await #expect(throws: LibraryError.cannotDeleteSystemShelf) {
            try await library.deleteShelf(shelf(.finished, in: library).id)
        }
    }
}
