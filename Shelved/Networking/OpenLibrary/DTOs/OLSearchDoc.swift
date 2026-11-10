import Foundation

/// One search result. Almost everything is optional because Open Library's
/// data is crowd-sourced and fields are often missing. One record with no
/// title shouldn't make the whole page fail to decode.
nonisolated struct OLSearchDoc: Decodable, Sendable {
    let key: String                 // "/works/OL893415W"
    let title: String?
    let authorName: [String]?
    let authorKey: [String]?
    let coverI: Int?
    let firstPublishYear: Int?

    /// Maps snake_case JSON keys to Swift names.
    /// (Alternative: `decoder.keyDecodingStrategy = .convertFromSnakeCase`.)
    nonisolated enum CodingKeys: String, CodingKey {
        case key, title
        case authorName = "author_name"
        case authorKey = "author_key"
        case coverI = "cover_i"
        case firstPublishYear = "first_publish_year"
    }
}
