import Foundation
import Testing
@testable import Shelved

struct OpenLibraryAPITests {
    @Test(arguments: [
        ("du", "du*"),
        ("dune", "dune*"),
        ("frank her", "frank her*"),
        ("  du  ", "du*"),          // trims first
        ("d", "d"),                 // one letter: too broad, leave as is
        ("frank h", "frank h"),
        ("\"dune\"", "\"dune\""),   // user's own exact-phrase syntax
        ("dun*", "dun*"),           // already a wildcard
        ("", ""),
    ] as [(String, String)])
    func prefixQuery(input: String, expected: String) {
        #expect(OpenLibraryAPI.prefixQuery(input) == expected)
    }

    @Test func searchEndpointSendsPrefixQuery() throws {
        let url = try OpenLibraryAPI.search(query: "du", page: 2, limit: 20).makeURL()
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        #expect(items.first { $0.name == "q" }?.value == "du*")
        #expect(items.first { $0.name == "page" }?.value == "2")
    }
}
