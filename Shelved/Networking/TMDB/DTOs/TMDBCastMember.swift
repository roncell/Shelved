import Foundation

nonisolated struct TMDBCastMember: Decodable, Sendable {
    let id: Int
    let name: String
    let character: String?
    /// Billing order: 0 is the lead.
    let order: Int?
}
