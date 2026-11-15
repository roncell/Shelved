import Foundation
@testable import Core
@testable import Data
@testable import Networking

/// A fake HTTP client that answers from a closure and counts requests.
///
/// `FakeHTTPClient` matches by path, but every Wikidata query goes to the
/// same path (/sparql); this one can look at the whole URL. The count lets a
/// test prove a cache works: "the second call made no request".
///
/// A struct with only the counter in an actor: the client itself can't be an
/// actor, because `send` returns a generic `Response` that isn't `Sendable`.
nonisolated struct RecordingHTTPClient: HTTPClient {
    private actor Counter {
        var value = 0
        func increment() { value += 1 }
    }

    private let respond: @Sendable (URL) -> String?
    private let counter = Counter()

    init(respond: @escaping @Sendable (URL) -> String?) {
        self.respond = respond
    }

    var requestCount: Int {
        get async { await counter.value }
    }

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        await counter.increment()
        let url = try endpoint.makeURL()
        guard let json = respond(url) else { throw NetworkError.httpStatus(404) }
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }
}
