import Foundation

/// Stands in for a catalog that can't run, e.g. TMDB with no token.
///
/// Every call throws, so the screens show a clear message, and the rest of
/// the app (books) keeps working. Better than an optional catalog that
/// every caller has to unwrap.
nonisolated struct UnavailableCatalog: MediaCatalog {
    let error: CatalogError

    init(_ error: CatalogError) {
        self.error = error
    }

    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage { throw error }
    func detail(for id: MediaID) async throws -> MediaDetail { throw error }
    func creator(for id: CreatorID) async throws -> CreatorDetail { throw error }
    func works(by id: CreatorID, page: Int) async throws -> SearchPage { throw error }
}
