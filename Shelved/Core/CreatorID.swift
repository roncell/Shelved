import Foundation

/// Identifies an author, director, or actor.
nonisolated enum CreatorID: Hashable, Sendable {
    /// An Open Library author ID, e.g. "OL79034A".
    case openLibraryAuthor(String)
}
