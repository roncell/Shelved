import Foundation

/// One book's place in a series, as the series source reports it.
///
/// Only a title and an ID: the cover and year come from the catalog, joined
/// by `workID`. Some entries have no Open Library ID (unpublished books,
/// gaps in the data); they're listed but can't be opened.
nonisolated struct SeriesEntry: Identifiable, Hashable, Sendable {
    /// As the source writes it: "1", "0.5" (a prequel novella).
    let position: String
    /// `position` as a number, for ordering.
    let sortKey: Double
    let title: String
    let workID: MediaID?

    var id: String { position }
}
