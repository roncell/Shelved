import Foundation

/// The raw JSON from /authors/{id}.json (only the fields we use).
nonisolated struct OLAuthor: Decodable, Sendable {
    let name: String?
    let personalName: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case name
        case personalName = "personal_name"
    }
}
