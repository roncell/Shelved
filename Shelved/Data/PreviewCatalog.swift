import Foundation

/// Canned data for SwiftUI previews: instant, offline, and never flaky.
nonisolated struct PreviewCatalog: MediaCatalog {
    static let items: [MediaItem] = [
        MediaItem(id: .openLibraryWork("OL893415W"), kind: .book, title: "Dune",
                  creators: [CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")],
                  coverURL: nil, year: 1965),
        MediaItem(id: .openLibraryWork("OL59863W"), kind: .book, title: "The Left Hand of Darkness",
                  creators: [CreatorSummary(id: .openLibraryAuthor("OL31301A"), name: "Ursula K. Le Guin")],
                  coverURL: nil, year: 1969),
    ]

    static let detail = MediaDetail(
        id: .openLibraryWork("OL893415W"), kind: .book, title: "Dune",
        creators: [CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")],
        coverURL: nil, year: 1965,
        summary: "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides.",
        subjects: ["Science fiction", "Arrakis", "Ecology"]
    )

    func search(query: String, page: Int) async throws -> SearchPage {
        SearchPage(items: Self.items, hasMore: false)
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        Self.detail
    }
}
