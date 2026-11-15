import Foundation

/// Where one book sits in a series: "Book 1 of 5 · A Song of Ice and Fire".
nonisolated struct SeriesMembership: Hashable, Sendable {
    let seriesID: SeriesID
    let seriesName: String
    /// As the source writes it, e.g. "1" or "0.5".
    let position: String
    /// nil when the series' numbering has gaps (see `Series.total`).
    let total: Int?
    /// How many books the series lists, for the search card.
    let entryCount: Int
}
