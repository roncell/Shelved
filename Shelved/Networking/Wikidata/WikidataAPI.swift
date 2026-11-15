import Foundation

/// SPARQL queries against Wikidata's public query service. Free, no key.
///
/// The properties used:
/// - P179 "part of the series", with the qualifier P1545 "series ordinal"
/// - P648 "Open Library ID" (on books and on authors)
/// - P50 "author"
nonisolated enum WikidataAPI {
    static let host = "query.wikidata.org"
    /// Wikimedia blocks requests without a descriptive User-Agent.
    static let userAgent = "Shelved/0.1 (iOS learning project)"

    /// Which numbered series is this book in?
    ///
    /// Matches by Open Library work ID **or** by author ID + English title.
    /// The fallback matters: Wikidata often stores an older, merged work ID
    /// (Dune is filed under OL893415W, which Open Library now redirects to
    /// OL893414W), and author IDs are far more stable.
    static func memberships(workID: String, authorIDs: [String], title: String) -> Endpoint<WikidataResponse> {
        var match = #"{ ?book wdt:P648 "\#(workID)" . }"#
        let authors = authorIDs.filter(isOpenLibraryID).map { #""\#($0)""# }.joined(separator: " ")
        if !authors.isEmpty {
            match += """
                 UNION { VALUES ?authorOL { \(authors) } ?author wdt:P648 ?authorOL .
                  ?book wdt:P50 ?author ; rdfs:label ?label .
                  FILTER(LANG(?label) = "en" && LCASE(STR(?label)) = "\(escape(title.lowercased()))") }
                """
        }
        return sparql("""
            SELECT DISTINCT ?series ?seriesLabel ?ord WHERE {
              \(match)
              ?book p:P179 ?statement . ?statement ps:P179 ?series ; pq:P1545 ?ord .
              SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
            }
            """)
    }

    /// Every numbered book in a series, with its Open Library work ID if any.
    static func series(qid: String) -> Endpoint<WikidataResponse> {
        sparql("""
            SELECT ?book ?bookLabel ?ord ?ol ?seriesName WHERE {
              ?book p:P179 ?statement . ?statement ps:P179 wd:\(qid) ; pq:P1545 ?ord .
              OPTIONAL { ?book wdt:P648 ?ol . FILTER(STRSTARTS(?ol, "OL") && STRENDS(?ol, "W")) }
              OPTIONAL { wd:\(qid) rdfs:label ?seriesName . FILTER(LANG(?seriesName) = "en") }
              SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
            }
            """)
    }

    /// IDs go into the query text, so only well-formed ones are allowed.
    /// The same reason SQL uses bound parameters: no query injection.
    static func isOpenLibraryID(_ id: String) -> Bool {
        id.wholeMatch(of: /OL[0-9]+[WA]/) != nil
    }

    static func isQID(_ id: String) -> Bool {
        id.wholeMatch(of: /Q[0-9]+/) != nil
    }

    /// Makes free text (a title) safe inside a "quoted" SPARQL string.
    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }

    private static func sparql(_ query: String) -> Endpoint<WikidataResponse> {
        Endpoint(host: host, path: "/sparql", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "json"),
        ])
    }
}
