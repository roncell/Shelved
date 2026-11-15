import Foundation

/// Everything screens need from a remote catalog of books (later films/TV).
///
/// ViewModels depend on this protocol, never on Open Library directly.
/// That lets tests and previews pass in a fake, and lets Open Library and
/// TMDB sit behind one interface (`CombinedCatalog` picks between them).
nonisolated protocol MediaCatalog: Sendable {
    /// `kind` filters results; nil means every kind this catalog has.
    /// A catalog asked for a kind it doesn't carry returns an empty page.
    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage
    func detail(for id: MediaID) async throws -> MediaDetail
    func creator(for id: CreatorID) async throws -> CreatorDetail
    /// A creator's works, most popular first. Returns `SearchPage` because
    /// it's the same "page of items + is there more?" shape as search.
    func works(by id: CreatorID, page: Int) async throws -> SearchPage
    /// Several items at once, keyed by the ID asked for (the item's own ID
    /// may differ if the record was merged). Missing IDs are left out.
    /// Used to put covers and years on a series from another source.
    func items(for ids: [MediaID]) async throws -> [MediaID: MediaItem]
}
