import Core
import Data
import Foundation

/// Every TMDB endpoint the app uses, in one place.
/// Docs: https://developer.themoviedb.org/reference/intro/getting-started
///
/// Authentication isn't here: the token goes in an `Authorization` header
/// set on the client (see `TMDBCatalog`), so it never appears in a URL or a log.
nonisolated enum TMDBAPI {
    static let host = "api.themoviedb.org"

    nonisolated enum ImageSize: String {
        case poster = "w342"
        case profile = "w185"
    }

    /// GET /3/search/multi: films, shows and people in one list.
    static func searchMulti(query: String, page: Int) -> Endpoint<TMDBPage<TMDBListItem>> {
        search(path: "/3/search/multi", query: query, page: page)
    }

    /// GET /3/search/movie
    static func searchMovies(query: String, page: Int) -> Endpoint<TMDBPage<TMDBListItem>> {
        search(path: "/3/search/movie", query: query, page: page)
    }

    /// GET /3/search/tv
    static func searchShows(query: String, page: Int) -> Endpoint<TMDBPage<TMDBListItem>> {
        search(path: "/3/search/tv", query: query, page: page)
    }

    /// GET /3/movie/329865?append_to_response=credits: details and cast in one request.
    static func movie(id: Int) -> Endpoint<TMDBMovie> {
        Endpoint(host: host, path: "/3/movie/\(id)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits"),
        ])
    }

    /// GET /3/tv/95396?append_to_response=credits
    static func show(id: Int) -> Endpoint<TMDBShow> {
        Endpoint(host: host, path: "/3/tv/\(id)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits"),
        ])
    }

    /// GET /3/person/137427
    static func person(id: Int) -> Endpoint<TMDBPerson> {
        Endpoint(host: host, path: "/3/person/\(id)")
    }

    /// GET /3/person/137427/combined_credits
    static func combinedCredits(personID: Int) -> Endpoint<TMDBCombinedCredits> {
        Endpoint(host: host, path: "/3/person/\(personID)/combined_credits")
    }

    /// Images live on a separate host, with the size in the path:
    /// https://image.tmdb.org/t/p/w342/abc.jpg
    static func imageURL(path: String?, size: ImageSize) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size.rawValue)\(path)")
    }

    private static func search(path: String, query: String, page: Int) -> Endpoint<TMDBPage<TMDBListItem>> {
        Endpoint(host: host, path: path, queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false"),
        ])
    }
}
