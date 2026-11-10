import Foundation

/// Canned data for SwiftUI previews: instant, offline, and never flaky.
nonisolated struct PreviewCatalog: MediaCatalog {
    static let herbert = CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")

    static let items: [MediaItem] = [
        MediaItem(id: .openLibraryWork("OL893414W"), kind: .book, title: "Dune",
                  creators: [herbert], coverURL: nil, year: 1965),
        MediaItem(id: .openLibraryWork("OL59800W"), kind: .book, title: "The Left Hand of Darkness",
                  creators: [CreatorSummary(id: .openLibraryAuthor("OL31353A"), name: "Ursula K. Le Guin")],
                  coverURL: nil, year: 1969),
    ]

    static let detail = MediaDetail(
        id: .openLibraryWork("OL893414W"), kind: .book, title: "Dune",
        creators: [herbert],
        coverURL: nil, year: 1965,
        summary: "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides.",
        subjects: ["Science fiction", "Ecology"],
        places: ["Arrakis"],
        characters: ["Paul Atreides", "Duncan Idaho"],
        timePeriods: [],
        links: []
    )

    static let creator = CreatorDetail(
        id: herbert.id, name: herbert.name,
        bio: "Franklin Patrick Herbert Jr. was an American science-fiction author, best known for Dune.",
        birthDate: "8 October 1920", deathDate: "11 February 1986",
        photoURL: nil
    )

    static let works: [MediaItem] = [
        MediaItem(id: .openLibraryWork("OL893414W"), kind: .book, title: "Dune",
                  creators: [herbert], coverURL: nil, year: 1965),
        MediaItem(id: .openLibraryWork("OL893461W"), kind: .book, title: "Dune Messiah",
                  creators: [herbert], coverURL: nil, year: 1969),
    ]

    func search(query: String, page: Int) async throws -> SearchPage {
        SearchPage(items: Self.items, hasMore: false)
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        Self.detail
    }

    func creator(for id: CreatorID) async throws -> CreatorDetail {
        Self.creator
    }

    func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        SearchPage(items: Self.works, hasMore: false)
    }
}
