import Foundation

/// One page of search results.
public nonisolated struct SearchPage: Hashable, Sendable {
    public let items: [MediaItem]
    public let hasMore: Bool

    public init(items: [MediaItem], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}
