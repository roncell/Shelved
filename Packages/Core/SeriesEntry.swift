import Foundation

/// One book's place in a series, as the series source reports it.
///
/// Only a title and an ID: the cover and year come from the catalog, joined
/// by `workID`. Some entries have no Open Library ID (unpublished books,
/// gaps in the data); they're listed but can't be opened.
public nonisolated struct SeriesEntry: Identifiable, Hashable, Sendable {
    /// As the source writes it: "1", "0.5" (a prequel novella).
    public let position: String
    /// `position` as a number, for ordering.
    public let sortKey: Double
    public let title: String
    public let workID: MediaID?

    public init(position: String, sortKey: Double, title: String, workID: MediaID?) {
        self.position = position
        self.sortKey = sortKey
        self.title = title
        self.workID = workID
    }

    public var id: String { position }
}
