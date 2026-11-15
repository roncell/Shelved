import Foundation
import Testing
@testable import Core
@testable import Data
@testable import Networking

private func item(_ title: String, _ id: MediaID) -> MediaItem {
    MediaItem(id: id, kind: id.kind, title: title, creators: [], coverURL: nil, year: nil)
}

private let book = item("Dune", .openLibraryWork("OL1W"))
private let book2 = item("Emma", .openLibraryWork("OL2W"))
private let film = item("Arrival", .tmdbFilm(1))

struct CombinedCatalogTests {
    @Test func allKindsInterleavesBothSources() async throws {
        let catalog = CombinedCatalog(
            openLibrary: StubCatalog(pages: [1: SearchPage(items: [book, book2], hasMore: false)]),
            tmdb: StubCatalog(pages: [1: SearchPage(items: [film], hasMore: true)])
        )

        let page = try await catalog.search(query: "x", kind: nil, page: 1)

        #expect(page.items.map(\.title) == ["Dune", "Arrival", "Emma"])
        #expect(page.hasMore)   // TMDB has more, even though Open Library doesn't
    }

    @Test func kindFilterOnlyAsksTheRightSource() async throws {
        let openLibrary = SpyCatalog(StubCatalog())
        let tmdb = SpyCatalog(StubCatalog())
        let catalog = CombinedCatalog(openLibrary: openLibrary, tmdb: tmdb)

        _ = try await catalog.search(query: "x", kind: .film, page: 1)

        #expect(await openLibrary.searches.isEmpty)
        #expect(await tmdb.searches.map(\.kind) == [.film])
    }

    /// No TMDB token (or TMDB down) shouldn't take book search down with it.
    @Test func oneSourceFailingStillShowsTheOther() async throws {
        let catalog = CombinedCatalog(
            openLibrary: StubCatalog(pages: [1: SearchPage(items: [book], hasMore: false)]),
            tmdb: UnavailableCatalog(.notConfigured)
        )

        let page = try await catalog.search(query: "x", kind: nil, page: 1)

        #expect(page.items == [book])
    }

    @Test func everySourceFailingThrows() async {
        let catalog = CombinedCatalog(
            openLibrary: StubCatalog(error: URLError(.notConnectedToInternet)),
            tmdb: UnavailableCatalog(.notConfigured)
        )

        await #expect(throws: URLError.self) {
            try await catalog.search(query: "x", kind: nil, page: 1)
        }
    }

    /// Asking for films alone, a missing token is the whole answer: show it.
    @Test func filmsWithoutTokenExplainWhy() async {
        let catalog = CombinedCatalog(openLibrary: StubCatalog(), tmdb: UnavailableCatalog(.notConfigured))

        await #expect(throws: CatalogError.notConfigured) {
            try await catalog.search(query: "x", kind: .film, page: 1)
        }
    }

    @Test func detailRoutesByID() async throws {
        let filmDetail = MediaDetail(saved: film)
        let catalog = CombinedCatalog(
            openLibrary: StubCatalog(error: CatalogError.unsupportedID),
            tmdb: StubCatalog(detail: filmDetail)
        )

        #expect(try await catalog.detail(for: film.id) == filmDetail)
    }
}
