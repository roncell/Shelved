import Foundation

/// `MediaCatalog` backed by TMDB: films, shows, and the people in them.
nonisolated struct TMDBCatalog: MediaCatalog {
    private let client: any HTTPClient

    init(client: any HTTPClient) {
        self.client = client
    }

    /// The token rides in a header on every request. Bearer auth (the "API
    /// Read Access Token") rather than the older `?api_key=` query item, so
    /// the secret never appears in URLs, which end up in logs and caches.
    init(readAccessToken: String) {
        self.init(client: URLSessionHTTPClient(headers: [
            "Authorization": "Bearer \(readAccessToken)",
            "Accept": "application/json",
        ]))
    }

    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage {
        let endpoint: Endpoint<TMDBPage<TMDBListItem>>
        switch kind {
        case .book: return SearchPage(items: [], hasMore: false)
        case .film: endpoint = TMDBAPI.searchMovies(query: query, page: page)
        case .show: endpoint = TMDBAPI.searchShows(query: query, page: page)
        case nil: endpoint = TMDBAPI.searchMulti(query: query, page: page)
        }
        return TMDBMapper.page(from: try await client.send(endpoint), defaultKind: kind)
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        switch id {
        case .tmdbFilm(let filmID):
            return TMDBMapper.detail(from: try await client.send(TMDBAPI.movie(id: filmID)))
        case .tmdbShow(let showID):
            return TMDBMapper.detail(from: try await client.send(TMDBAPI.show(id: showID)))
        case .openLibraryWork:
            throw CatalogError.unsupportedID
        }
    }

    func creator(for id: CreatorID) async throws -> CreatorDetail {
        switch id {
        case .tmdbPerson(let personID):
            return TMDBMapper.creatorDetail(from: try await client.send(TMDBAPI.person(id: personID)))
        case .openLibraryAuthor:
            throw CatalogError.unsupportedID
        }
    }

    /// TMDB returns a person's whole filmography in one response, so it all
    /// comes back as page 1. Even prolific actors have a few hundred
    /// credits, which a lazy `List` handles fine.
    func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        switch id {
        case .tmdbPerson(let personID):
            guard page == 1 else { return SearchPage(items: [], hasMore: false) }
            let credits = try await client.send(TMDBAPI.combinedCredits(personID: personID))
            return SearchPage(items: TMDBMapper.works(from: credits), hasMore: false)
        case .openLibraryAuthor:
            throw CatalogError.unsupportedID
        }
    }
}
