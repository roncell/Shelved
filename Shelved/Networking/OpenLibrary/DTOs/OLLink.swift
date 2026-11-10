import Foundation

/// `{ "title": "New York Times review", "url": "http://…", "type": {...} }`
nonisolated struct OLLink: Decodable, Sendable {
    let title: String?
    let url: String?
}
