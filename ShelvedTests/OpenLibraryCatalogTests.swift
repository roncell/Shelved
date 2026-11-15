import Foundation
import Testing
@testable import Core
@testable import Data
@testable import Networking

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

    /// One search for the batch; a merged ID missing from the index is
    /// fetched on its own and keyed by the ID that was asked for.
    @Test func itemsBatchFollowsRedirectsForMissingIDs() async throws {
        let catalog = OpenLibraryCatalog(client: FakeHTTPClient(responses: [
            "/search.json": """
                {"numFound": 1, "start": 0, "docs": [
                    {"key": "/works/OL893461W", "title": "Dune Messiah", "cover_i": 2}]}
                """,
            "/works/OL893415W.json": #"{"key": "/works/OL893415W", "type": {"key": "/type/redirect"}, "location": "/works/OL893414W"}"#,
            "/works/OL893414W.json": #"{"key": "/works/OL893414W", "title": "Dune", "covers": [7]}"#,
        ]))

        let items = try await catalog.items(for: [.openLibraryWork("OL893461W"), .openLibraryWork("OL893415W")])

        #expect(items[.openLibraryWork("OL893461W")]?.title == "Dune Messiah")
        #expect(items[.openLibraryWork("OL893415W")]?.id == .openLibraryWork("OL893414W"))   // canonical
    }
}
