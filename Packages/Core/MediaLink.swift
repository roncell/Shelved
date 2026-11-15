import Foundation

/// An external page about an item, e.g. a review or an official site.
public nonisolated struct MediaLink: Hashable, Sendable {
    public let title: String
    public let url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}
