import Foundation

/// Describes one API call *and* the type its response decodes into.
///
/// The generic `Response` is a "phantom type": it isn't stored anywhere,
/// but it ties the endpoint to its result, so
/// `client.send(OpenLibraryAPI.work(id:))` returns an `OLWork` with no casting.
nonisolated struct Endpoint<Response: Decodable>: Sendable {
    let host: String
    /// Must start with "/".
    let path: String
    var queryItems: [URLQueryItem] = []

    func makeURL() throws -> URL {
        // Building from components (instead of URL(string:)!) avoids force
        // unwraps and handles percent-encoding of query values for us.
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw NetworkError.invalidURL }
        return url
    }
}
