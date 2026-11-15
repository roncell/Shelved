import Foundation

/// Identifies a series. A case per source, like `MediaID`.
public nonisolated enum SeriesID: Hashable, Sendable {
    /// A Wikidata item ID, e.g. "Q45875" (A Song of Ice and Fire).
    case wikidata(String)
}
