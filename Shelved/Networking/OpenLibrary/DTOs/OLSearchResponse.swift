import Foundation

/// The raw JSON from /search.json. DTO = "data transfer object":
/// it mirrors the API exactly and never leaves the networking layer.
nonisolated struct OLSearchResponse: Decodable, Sendable {
    let numFound: Int
    let start: Int
    let docs: [OLSearchDoc]
}
