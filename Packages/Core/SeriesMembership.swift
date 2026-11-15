import Foundation

/// Where one book sits in a series: "Book 1 of 5 · A Song of Ice and Fire".
public nonisolated struct SeriesMembership: Hashable, Sendable {
    public let seriesID: SeriesID
    public let seriesName: String
    /// As the source writes it, e.g. "1" or "0.5".
    public let position: String
    /// nil when the series' numbering has gaps (see `Series.total`).
    public let total: Int?
    /// How many books the series lists, for the search card.
    public let entryCount: Int

    public init(seriesID: SeriesID, seriesName: String, position: String, total: Int?, entryCount: Int) {
        self.seriesID = seriesID
        self.seriesName = seriesName
        self.position = position
        self.total = total
        self.entryCount = entryCount
    }
}
