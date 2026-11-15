import Foundation

nonisolated struct TMDBCrewMember: Decodable, Sendable {
    let id: Int
    let name: String
    /// "Director", "Screenplay", "Original Music Composer"…
    let job: String?
}
