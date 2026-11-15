import Core
import Data
import Foundation

/// A film, show, or person as it appears in lists: search results and a
/// person's credits. One DTO for all of them because TMDB uses the same
/// fields, with films using `title`/`release_date` and shows `name`/`first_air_date`.
nonisolated struct TMDBListItem: Decodable, Sendable {
    let id: Int
    /// "movie", "tv" or "person". Missing from single-kind searches.
    let mediaType: String?
    let title: String?
    let name: String?
    let releaseDate: String?
    let firstAirDate: String?
    let posterPath: String?
    let popularity: Double?
    let genreIDs: [Int]?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, title, name, popularity
        case mediaType = "media_type"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case genreIDs = "genre_ids"
    }
}
