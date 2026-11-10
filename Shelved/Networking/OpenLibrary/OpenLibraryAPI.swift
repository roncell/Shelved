import Foundation

/// Every Open Library endpoint the app uses, in one place.
/// Docs: https://openlibrary.org/developers/api
nonisolated enum OpenLibraryAPI {
    static let host = "openlibrary.org"

    /// Open Library asks apps to identify themselves. Add a contact email
    /// before shipping, e.g. "Shelved/0.1 (you@example.com)".
    static let userAgent = "Shelved/0.1 (iOS learning project)"

    /// Ask only for the fields we map. Smaller responses, faster decoding.
    private static let searchFields = "key,title,author_name,author_key,cover_i,first_publish_year"

    /// GET /search.json?q=du*&page=1&limit=20
    static func search(query: String, page: Int, limit: Int) -> Endpoint<OLSearchResponse> {
        Endpoint(host: host, path: "/search.json", queryItems: [
            URLQueryItem(name: "q", value: prefixQuery(query)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: searchFields),
        ])
    }

    /// Turns the last word into a prefix match so results appear while typing:
    ///   "du"        → "du*"          (matches Dune, Dubliners…)
    ///   "frank her" → "frank her*"
    ///
    /// Open Library matches whole words by default, so "du" alone would only
    /// find titles containing the word "du". Only the last word gets `*`,
    /// because earlier words are already complete.
    ///
    /// Left unchanged when the last word is a single character (a one-letter
    /// prefix matches nearly everything and is slow), or when it ends in
    /// punctuation like `"` or `*` (the user is writing their own query syntax).
    static func prefixQuery(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastWord = trimmed.split(separator: " ").last,
              lastWord.count >= 2,
              lastWord.last?.isLetter == true || lastWord.last?.isNumber == true
        else { return trimmed }
        return trimmed + "*"
    }

    /// GET /works/OL893415W.json
    static func work(id: String) -> Endpoint<OLWork> {
        Endpoint(host: host, path: "/works/\(id).json")
    }

    /// GET /authors/OL79034A.json
    static func author(id: String) -> Endpoint<OLAuthor> {
        Endpoint(host: host, path: "/authors/\(id).json")
    }
}
