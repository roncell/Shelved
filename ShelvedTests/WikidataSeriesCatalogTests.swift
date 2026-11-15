import Foundation
import Testing
@testable import Shelved

private let entity = "http://www.wikidata.org/entity/"
private let dune = MediaItem(
    id: .openLibraryWork("OL893414W"), kind: .book, title: "Dune",
    creators: [CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")],
    coverURL: nil, year: 1965
)

/// Answers the membership query with two candidate series, and each series
/// query with its books. "Dune universe" has more books but fewer we can open.
private func duneClient() -> RecordingHTTPClient {
    RecordingHTTPClient { url in
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "query" }?.value ?? ""
        if query.contains("SELECT DISTINCT ?series") {
            return sparqlJSON([
                ["series": entity + "Q6095696", "seriesLabel": "Dune", "ord": "1"],
                ["series": entity + "Q999", "seriesLabel": "Dune universe", "ord": "1"],
            ])
        }
        if query.contains("wd:Q6095696") {
            return sparqlJSON([
                ["book": entity + "Q1", "bookLabel": "Dune", "ord": "1", "ol": "OL893415W", "seriesName": "Dune"],
                ["book": entity + "Q2", "bookLabel": "Dune Messiah", "ord": "2", "ol": "OL893461W", "seriesName": "Dune"],
            ])
        }
        if query.contains("wd:Q999") {
            return sparqlJSON([
                ["book": entity + "Q1", "bookLabel": "Dune", "ord": "1", "seriesName": "Dune universe"],
                ["book": entity + "Q3", "bookLabel": "Prequel", "ord": "2"],
                ["book": entity + "Q4", "bookLabel": "Sequel", "ord": "3", "ol": "OL5W"],
            ])
        }
        return nil
    }
}

struct WikidataSeriesCatalogTests {
    @Test func membershipPicksTheSeriesWithMostOpenableBooks() async throws {
        let catalog = WikidataSeriesCatalog(client: duneClient())

        let membership = try #require(try await catalog.membership(of: dune))

        #expect(membership.seriesID == .wikidata("Q6095696"))
        #expect(membership.position == "1")
        #expect(membership.total == 2)
    }

    @Test func secondLookupIsServedFromCache() async throws {
        let client = duneClient()
        let catalog = WikidataSeriesCatalog(client: client)

        _ = try await catalog.membership(of: dune)
        let afterFirst = await client.requestCount
        _ = try await catalog.membership(of: dune)
        _ = try await catalog.series(.wikidata("Q6095696"))   // loaded while choosing

        #expect(await client.requestCount == afterFirst)
    }

    @Test func filmsAreNeverLookedUp() async throws {
        let client = duneClient()
        let catalog = WikidataSeriesCatalog(client: client)
        let film = MediaItem(id: .tmdbFilm(1), kind: .film, title: "Dune", creators: [], coverURL: nil, year: 2021)

        #expect(try await catalog.membership(of: film) == nil)
        #expect(await client.requestCount == 0)
    }
}
