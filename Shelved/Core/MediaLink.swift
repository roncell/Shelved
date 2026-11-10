import Foundation

/// An external page about an item, e.g. a review or an official site.
nonisolated struct MediaLink: Hashable, Sendable {
    let title: String
    let url: URL
}
