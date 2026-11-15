import Core
import Data
import Foundation

/// GET /3/tv/{id}?append_to_response=credits
nonisolated struct TMDBShow: Decodable, Sendable {
    let id: Int
    let name: String?
    let overview: String?
    let firstAirDate: String?
    let posterPath: String?
    let genres: [TMDBGenre]?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let homepage: String?
    let createdBy: [TMDBPersonRef]?
    let credits: TMDBCredits?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, homepage, credits
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case createdBy = "created_by"
    }
}
