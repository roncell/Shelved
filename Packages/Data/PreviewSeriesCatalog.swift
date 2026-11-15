import Core
import Foundation

/// Canned series data for previews and UI tests: Dune books 1–3.
public nonisolated struct PreviewSeriesCatalog: SeriesCatalog {
    public init() {}

    public static let dune = Series(
        id: .wikidata("Q6095696"),
        name: "Dune",
        entries: [
            SeriesEntry(position: "1", sortKey: 1, title: "Dune", workID: .openLibraryWork("OL893414W")),
            SeriesEntry(position: "2", sortKey: 2, title: "Dune Messiah", workID: .openLibraryWork("OL893461W")),
            SeriesEntry(position: "3", sortKey: 3, title: "Children of Dune", workID: nil),
        ]
    )

    public func membership(of item: MediaItem) async throws -> SeriesMembership? {
        guard let entry = Self.dune.entries.first(where: { $0.workID == item.id }) else { return nil }
        return SeriesMembership(
            seriesID: Self.dune.id, seriesName: Self.dune.name, position: entry.position,
            total: Self.dune.total, entryCount: Self.dune.entries.count
        )
    }

    public func series(_ id: SeriesID) async throws -> Series {
        Self.dune
    }
}
