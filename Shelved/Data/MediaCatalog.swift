import Foundation

/// Everything screens need from a remote catalog of books (later films/TV).
///
/// ViewModels depend on this protocol, never on Open Library directly.
/// That lets tests and previews pass in a fake, and in Phase 6 a TMDB
/// catalog can slot in behind the same interface.
nonisolated protocol MediaCatalog: Sendable {
    func search(query: String, page: Int) async throws -> SearchPage
    func detail(for id: MediaID) async throws -> MediaDetail
    func creator(for id: CreatorID) async throws -> CreatorDetail
    /// A creator's works, most popular first. Returns `SearchPage` because
    /// it's the same "page of items + is there more?" shape as search.
    func works(by id: CreatorID, page: Int) async throws -> SearchPage
}
