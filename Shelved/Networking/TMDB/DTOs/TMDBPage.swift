import Foundation

/// TMDB's envelope for every paged list (search results).
nonisolated struct TMDBPage<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [Item]
    let totalPages: Int

    nonisolated enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}
