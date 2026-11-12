import Foundation

/// The user's saved items and shelves. The single source of truth for "my library".
///
/// Speaks only in value types (`ShelfSummary`, `LibraryItem`), never SwiftData
/// objects, so ViewModels and views can't accidentally depend on how or where
/// data is stored. Swap SwiftData for something else and only the
/// implementation changes.
///
/// `@MainActor` because the implementation uses SwiftData's main context,
/// which belongs to the main thread. Methods are still `async`: callers
/// already `await`, so moving the store to a background `@ModelActor`
/// later wouldn't change a single call site.
@MainActor
protocol LibraryRepository: AnyObject {
    /// System shelves first, then the user's own, in display order.
    func shelves() async throws -> [ShelfSummary]
    /// Most recently added first.
    func items(on shelf: ShelfID) async throws -> [LibraryItem]
    /// nil if the item isn't in the library.
    func item(for id: MediaID) async throws -> LibraryItem?

    /// Adds the item to a shelf, or moves it there if it's already saved.
    /// An item is on exactly one shelf at a time.
    @discardableResult
    func save(_ media: MediaItem, to shelf: ShelfID) async throws -> LibraryItem
    /// Removes the item and its rating, review, and progress. No-op if not saved.
    func remove(_ id: MediaID) async throws
    func updateLog(_ log: ReadingLog, for id: MediaID) async throws

    func createShelf(named name: String) async throws -> ShelfSummary
    /// Custom shelves only. Their items move to Want to Read rather than
    /// being deleted, so nobody loses their ratings by tidying shelves.
    func deleteShelf(_ id: ShelfID) async throws
}
