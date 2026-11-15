import Foundation

/// The `credits` block added by `append_to_response=credits`.
nonisolated struct TMDBCredits: Decodable, Sendable {
    let cast: [TMDBCastMember]?
    let crew: [TMDBCrewMember]?
}
