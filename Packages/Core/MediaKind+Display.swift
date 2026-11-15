import Foundation

/// Wording that depends on what kind of thing it is. Lives with the domain
/// type so every screen says "Directed by" or "Episode 3" the same way.
extension MediaKind {
    /// Header for the creators section: authors, directors, or show creators.
    public var creatorsHeading: String {
        switch self {
        case .book: String(localized: "By")
        case .film: String(localized: "Directed by")
        case .show: String(localized: "Created by")
        }
    }

    /// Films are watched in one sitting, so only books and shows log progress.
    public var tracksProgress: Bool {
        switch self {
        case .book, .show: true
        case .film: false
        }
    }

    /// "Page 212 of 617", "Episode 3 of 9", or nil when there's nothing to say.
    public func progressText(_ progress: Int?, total: Int?) -> String? {
        guard tracksProgress, let progress else { return nil }
        switch (self, total) {
        case (.show, let total?): return String(localized: "Episode \(progress) of \(total)")
        case (.show, nil): return String(localized: "Episode \(progress)")
        case (_, let total?): return String(localized: "Page \(progress) of \(total)")
        case (_, nil): return String(localized: "Page \(progress)")
        }
    }
}
