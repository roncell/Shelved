import Foundation

/// Every screen that can be pushed onto a tab's stack.
///
/// Routes carry IDs, never full model objects. That keeps them cheap to hash,
/// easy to build from a deep link, and means each screen loads its own fresh data.
enum Route: Hashable, Sendable {
    case itemDetail(MediaID)
    case creator(CreatorID)
    case shelf(ShelfID)
    /// Edit your rating, review, progress, and dates for a saved item.
    case review(MediaID)
}
