import Core
import Data
import Foundation

/// GET /3/person/{id}
nonisolated struct TMDBPerson: Decodable, Sendable {
    let id: Int
    let name: String?
    /// "" (not null) when TMDB has none.
    let biography: String?
    /// "1967-10-03"
    let birthday: String?
    let deathday: String?
    let profilePath: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, biography, birthday, deathday
        case profilePath = "profile_path"
    }
}
