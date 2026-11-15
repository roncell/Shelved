import Foundation

/// Identifies an author, director, or actor.
public nonisolated enum CreatorID: Hashable, Sendable {
    /// An Open Library author ID, e.g. "OL79034A".
    case openLibraryAuthor(String)
    /// A TMDB person ID, e.g. 137427 (Denis Villeneuve). One ID whether
    /// they directed, acted, or both.
    case tmdbPerson(Int)
}
