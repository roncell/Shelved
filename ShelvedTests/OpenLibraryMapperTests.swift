import Foundation
import Testing
@testable import Shelved

/// Decodes realistic JSON and checks the domain models that come out.
/// No network: these run in milliseconds and never flake.
struct OpenLibraryMapperTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func mapsSearchDocToMediaItem() throws {
        let response = try decode(OLSearchResponse.self, """
        {"numFound": 1, "start": 0, "docs": [{
            "key": "/works/OL893415W", "title": "Dune",
            "author_name": ["Frank Herbert"], "author_key": ["OL79034A"],
            "cover_i": 12345, "first_publish_year": 1965
        }]}
        """)

        let item = try #require(OpenLibraryMapper.item(from: response.docs[0]))

        #expect(item.id == .openLibraryWork("OL893415W"))
        #expect(item.title == "Dune")
        #expect(item.creators == [CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")])
        #expect(item.coverURL?.absoluteString == "https://covers.openlibrary.org/b/id/12345-M.jpg")
        #expect(item.year == 1965)
    }

    @Test func dropsDocsWithoutTitle() throws {
        let response = try decode(OLSearchResponse.self, """
        {"numFound": 1, "start": 0, "docs": [{"key": "/works/OL1W"}]}
        """)
        #expect(OpenLibraryMapper.item(from: response.docs[0]) == nil)
    }

    @Test func decodesDescriptionInBothShapes() throws {
        let plain = try decode(OLWork.self, """
        {"key": "/works/OL1W", "description": "A desert planet."}
        """)
        let object = try decode(OLWork.self, """
        {"key": "/works/OL1W", "description": {"type": "/type/text", "value": "A desert planet."}}
        """)
        #expect(plain.description?.value == "A desert planet.")
        #expect(object.description?.value == "A desert planet.")
    }

    @Test func detailSkipsMissingCoverPlaceholder() throws {
        let work = try decode(OLWork.self, """
        {"key": "/works/OL1W", "title": "Dune", "covers": [-1, 555], "first_publish_date": "August 1965"}
        """)
        let detail = OpenLibraryMapper.detail(from: work, id: .openLibraryWork("OL1W"), creators: [])

        #expect(detail.coverURL?.absoluteString == "https://covers.openlibrary.org/b/id/555-L.jpg")
        #expect(detail.year == 1965)
    }

    @Test func detailMapsSubjectListsAndDropsBadLinks() throws {
        let work = try decode(OLWork.self, """
        {"key": "/works/OL1W", "title": "Dune",
         "subject_places": ["Arrakis"], "subject_people": ["Paul Atreides"],
         "links": [
            {"title": "NYT review", "url": "https://nytimes.com/dune"},
            {"title": "", "url": "https://example.com"},
            {"title": "Broken", "url": "not a url"}
         ]}
        """)
        let detail = OpenLibraryMapper.detail(from: work, id: .openLibraryWork("OL1W"), creators: [])

        #expect(detail.places == ["Arrakis"])
        #expect(detail.characters == ["Paul Atreides"])
        #expect(detail.timePeriods.isEmpty)
        #expect(detail.links.map(\.title) == ["NYT review"])
    }

    @Test func mapsAuthorToCreatorDetail() throws {
        let author = try decode(OLAuthor.self, """
        {"name": "Frank Herbert", "birth_date": "8 October 1920", "death_date": "11 February 1986",
         "bio": {"type": "/type/text", "value": "American author."}, "photos": [-1, 14852808]}
        """)

        let creator = OpenLibraryMapper.creatorDetail(from: author, authorID: "OL79034A")

        #expect(creator.id == .openLibraryAuthor("OL79034A"))
        #expect(creator.name == "Frank Herbert")
        #expect(creator.bio == "American author.")
        #expect(creator.birthDate == "8 October 1920")
        #expect(creator.photoURL?.absoluteString == "https://covers.openlibrary.org/a/id/14852808-L.jpg")
    }

    @Test func creatorDetailFallsBackWhenNameMissing() throws {
        let author = try decode(OLAuthor.self, #"{"personal_name": "Herbert, Frank"}"#)
        #expect(OpenLibraryMapper.creatorDetail(from: author, authorID: "X").name == "Herbert, Frank")

        let nameless = try decode(OLAuthor.self, "{}")
        #expect(OpenLibraryMapper.creatorDetail(from: nameless, authorID: "X").name == "Unknown Author")
    }

    @Test func recognizesRedirectRecords() throws {
        let redirect = try decode(OLWork.self, """
        {"key": "/works/OL893415W", "type": {"key": "/type/redirect"}, "location": "/works/OL893414W"}
        """)
        let real = try decode(OLWork.self, """
        {"key": "/works/OL893414W", "type": {"key": "/type/work"}, "title": "Dune"}
        """)
        #expect(redirect.redirectKey == "/works/OL893414W")
        #expect(real.redirectKey == nil)
    }

    // Parameterized test: one test function, run once per argument.
    @Test(arguments: [
        ("1965", 1965),
        ("August 1965", 1965),
        ("Aug 01, 1965", 1965),
        ("unknown", nil),
    ] as [(String, Int?)])
    func parsesYear(text: String, expected: Int?) {
        #expect(OpenLibraryMapper.year(from: text) == expected)
    }

    @Test func extractsIDFromKey() {
        #expect(OpenLibraryMapper.id(fromKey: "/works/OL893415W") == "OL893415W")
        #expect(OpenLibraryMapper.id(fromKey: "/authors/OL79034A") == "OL79034A")
        #expect(OpenLibraryMapper.id(fromKey: "") == nil)
    }
}
