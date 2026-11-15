import Foundation

/// GET /3/movie/{id}?append_to_response=credits
nonisolated struct TMDBMovie: Decodable, Sendable {
    let id: Int
    let title: String?
    let overview: String?
    let releaseDate: String?
    let posterPath: String?
    let genres: [TMDBGenre]?
    /// Minutes. 0 when TMDB doesn't know.
    let runtime: Int?
    let homepage: String?
    let imdbID: String?
    let credits: TMDBCredits?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, title, overview, genres, runtime, homepage, credits
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case imdbID = "imdb_id"
    }
}
