import Foundation

/// One page of search results.
nonisolated struct SearchPage: Hashable, Sendable {
    let items: [MediaItem]
    let hasMore: Bool
}
