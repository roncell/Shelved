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
        film,
        show,
    ]

    static let villeneuve = CreatorSummary(id: .tmdbPerson(137427), name: "Denis Villeneuve")

    static let film = MediaItem(id: .tmdbFilm(329865), kind: .film, title: "Arrival",
                                creators: [villeneuve], coverURL: nil, year: 2016)

    static let show = MediaItem(id: .tmdbShow(95396), kind: .show, title: "Severance",
                                creators: [CreatorSummary(id: .tmdbPerson(1215054), name: "Dan Erickson")],
                                coverURL: nil, year: 2022)

    static let filmDetail = MediaDetail(
        id: film.id, kind: .film, title: film.title,
        creators: [villeneuve],
        coverURL: nil, year: 2016,
        summary: "A linguist is recruited to communicate with alien visitors.",
        subjects: ["Drama", "Science Fiction"],
        places: [], characters: [], timePeriods: [], links: [],
        cast: [
            CastCredit(person: CreatorSummary(id: .tmdbPerson(9273), name: "Amy Adams"), character: "Louise Banks"),
            CastCredit(person: CreatorSummary(id: .tmdbPerson(17604), name: "Jeremy Renner"), character: "Ian Donnelly"),
        ],
        runtimeMinutes: 116
    )

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

    static let director = CreatorDetail(
        id: villeneuve.id, name: villeneuve.name,
        bio: "Denis Villeneuve is a Canadian filmmaker known for Arrival, Blade Runner 2049 and Dune.",
        birthDate: "October 3, 1967", deathDate: nil,
        photoURL: nil
    )

    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage {
        SearchPage(items: Self.items.filter { kind == nil || $0.kind == kind }, hasMore: false)
    }

    /// Answers by kind, so a film opens a film even though there's one detail per kind.
    func detail(for id: MediaID) async throws -> MediaDetail {
        switch id {
        case .openLibraryWork: Self.detail
        case .tmdbFilm: Self.filmDetail
        case .tmdbShow: MediaDetail(saved: Self.show)
        }
    }

    func creator(for id: CreatorID) async throws -> CreatorDetail {
        switch id {
        case .openLibraryAuthor: Self.creator
        case .tmdbPerson: Self.director
        }
    }

    func items(for ids: [MediaID]) async throws -> [MediaID: MediaItem] {
        let known = Self.items + Self.works
        var found: [MediaID: MediaItem] = [:]
        for id in ids {
            if let item = known.first(where: { $0.id == id }) { found[id] = item }
        }
        return found
    }

    func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        switch id {
        case .openLibraryAuthor: SearchPage(items: Self.works, hasMore: false)
        case .tmdbPerson: SearchPage(items: [Self.film], hasMore: false)
        }
    }
}
