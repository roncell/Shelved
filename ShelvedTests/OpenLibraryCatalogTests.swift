import Foundation
import Testing
@testable import Shelved

/// Serves canned JSON by URL path, so `OpenLibraryCatalog` runs its real
/// logic (redirects, mapping, task groups) without any network.
nonisolated struct FakeHTTPClient: HTTPClient {
    let responses: [String: String]

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        guard let json = responses[endpoint.path] else {
            throw NetworkError.httpStatus(404)
        }
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }
}

struct OpenLibraryCatalogTests {
    @Test func detailFollowsRedirectToCanonicalWork() async throws {
        let catalog = OpenLibraryCatalog(client: FakeHTTPClient(responses: [
            "/works/OL893415W.json": """
                {"key": "/works/OL893415W", "type": {"key": "/type/redirect"}, "location": "/works/OL893414W"}
                """,
            "/works/OL893414W.json": """
                {"key": "/works/OL893414W", "title": "Dune", "type": {"key": "/type/work"},
                 "authors": [{"author": {"key": "/authors/OL79034A"}}]}
                """,
            "/authors/OL79034A.json": """
                {"name": "Frank Herbert"}
                """,
        ]))

        let detail = try await catalog.detail(for: .openLibraryWork("OL893415W"))

        #expect(detail.title == "Dune")
        #expect(detail.id == .openLibraryWork("OL893414W"))   // the canonical ID, not the stale one
        #expect(detail.creators.map(\.name) == ["Frank Herbert"])
    }

    @Test func redirectLoopThrowsInsteadOfHanging() async {
        let catalog = OpenLibraryCatalog(client: FakeHTTPClient(responses: [
            "/authors/A.json": #"{"type": {"key": "/type/redirect"}, "location": "/authors/B"}"#,
            "/authors/B.json": #"{"type": {"key": "/type/redirect"}, "location": "/authors/A"}"#,
        ]))

        await #expect(throws: NetworkError.self) {
            try await catalog.creator(for: .openLibraryAuthor("A"))
        }
    }

    @Test func worksMapsSearchResults() async throws {
        let catalog = OpenLibraryCatalog(client: FakeHTTPClient(responses: [
            "/search.json": """
                {"numFound": 144, "start": 0, "docs": [
                    {"key": "/works/OL893414W", "title": "Dune", "first_publish_year": 1965}
                ]}
                """,
        ]))

        let page = try await catalog.works(by: .openLibraryAuthor("OL79034A"), page: 1)

        #expect(page.items.map(\.title) == ["Dune"])
        #expect(page.hasMore)
    }
}
