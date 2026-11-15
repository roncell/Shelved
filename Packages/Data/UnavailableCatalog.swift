import Core
import Foundation

/// Stands in for a catalog that can't run, e.g. TMDB with no token.
///
/// Every call throws, so the screens show a clear message, and the rest of
/// the app (books) keeps working. Better than an optional catalog that
/// every caller has to unwrap.
public nonisolated struct UnavailableCatalog: MediaCatalog {
    public let error: CatalogError

    public init(_ error: CatalogError) {
        self.error = error
    }

    public func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage { throw error }
    public func detail(for id: MediaID) async throws -> MediaDetail { throw error }
    public func creator(for id: CreatorID) async throws -> CreatorDetail { throw error }
    public func works(by id: CreatorID, page: Int) async throws -> SearchPage { throw error }
    public func items(for ids: [MediaID]) async throws -> [MediaID: MediaItem] { throw error }
}
