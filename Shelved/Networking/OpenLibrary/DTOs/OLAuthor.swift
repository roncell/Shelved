import Foundation

/// The raw JSON from /authors/{id}.json (only the fields we use).
nonisolated struct OLAuthor: Decodable, Sendable, OLRedirectable {
    let name: String?
    let personalName: String?
    let bio: OLText?                // string or {type, value}, like work descriptions
    let birthDate: String?
    let deathDate: String?
    let photos: [Int]?              // can contain -1 for "no photo"
    let type: OLKeyRef?
    let location: String?           // set only on redirect records

    nonisolated enum CodingKeys: String, CodingKey {
        case name, bio, photos, type, location
        case personalName = "personal_name"
        case birthDate = "birth_date"
        case deathDate = "death_date"
    }
}
