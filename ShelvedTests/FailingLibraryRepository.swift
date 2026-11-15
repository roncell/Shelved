import Foundation
@testable import Core
@testable import Data

/// A stub library where every call throws, for testing error paths that
/// the real repository can't easily be pushed into (a corrupt store, a full disk).
@MainActor
final class FailingLibraryRepository: LibraryRepository {
    struct StoreUnavailable: Error {}

    private let error: any Error

    init(error: any Error = StoreUnavailable()) {
        self.error = error
    }

    func shelves() throws -> [ShelfSummary] { throw error }
    func items(on shelf: ShelfID) throws -> [LibraryItem] { throw error }
    func item(for id: MediaID) throws -> LibraryItem? { throw error }
    func save(_ media: MediaItem, to shelf: ShelfID) throws -> LibraryItem { throw error }
    func remove(_ id: MediaID) throws { throw error }
    func updateLog(_ log: ReadingLog, for id: MediaID) throws { throw error }
    func createShelf(named name: String) throws -> ShelfSummary { throw error }
    func deleteShelf(_ id: ShelfID) throws { throw error }
}
