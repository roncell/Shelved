import Foundation
import Testing
@testable import Shelved

struct TMDBCatalogTests {
    @Test func searchPicksTheEndpointForTheKind() async throws {
        let catalog = TMDBCatalog(client: FakeHTTPClient(responses: [
            "/3/search/tv": #"{"page": 1, "total_pages": 1, "results": [{"id": 95396, "name": "Severance"}]}"#,
        ]))

        let page = try await catalog.search(query: "sev", kind: .show, page: 1)

        #expect(page.items.map(\.id) == [.tmdbShow(95396)])
    }

    @Test func bookSearchMakesNoRequest() async throws {
        // No responses at all: any request would throw a 404.
        let catalog = TMDBCatalog(client: FakeHTTPClient(responses: [:]))

        let page = try await catalog.search(query: "dune", kind: .book, page: 1)

        #expect(page.items.isEmpty)
    }

    @Test func personWorksComeBackAsOnePage() async throws {
        let catalog = TMDBCatalog(client: FakeHTTPClient(responses: [
            "/3/person/137427/combined_credits": """
                {"cast": [], "crew": [{"id": 329865, "media_type": "movie", "title": "Arrival", "job": "Director"}]}
                """,
        ]))

        let first = try await catalog.works(by: .tmdbPerson(137427), page: 1)
        let second = try await catalog.works(by: .tmdbPerson(137427), page: 2)

        #expect(first.items.map(\.title) == ["Arrival"])
        #expect(!first.hasMore)
        #expect(second.items.isEmpty)
    }

    @Test func openLibraryIDsAreRejected() async {
        let catalog = TMDBCatalog(client: FakeHTTPClient(responses: [:]))

        await #expect(throws: CatalogError.unsupportedID) {
            try await catalog.detail(for: .openLibraryWork("OL893414W"))
        }
    }
}
