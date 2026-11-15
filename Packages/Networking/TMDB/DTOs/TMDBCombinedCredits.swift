import Core
import Data
import Foundation

/// GET /3/person/{id}/combined_credits: everything they acted in (`cast`)
/// or worked on (`crew`), films and shows together. Not paged.
nonisolated struct TMDBCombinedCredits: Decodable, Sendable {
    let cast: [TMDBListItem]?
    let crew: [TMDBListItem]?
}
