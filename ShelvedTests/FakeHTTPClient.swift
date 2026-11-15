import Foundation
@testable import Shelved

/// Serves canned JSON by URL path, so a catalog runs its real logic
/// (redirects, mapping, task groups) without any network.
nonisolated struct FakeHTTPClient: HTTPClient {
    let responses: [String: String]

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        guard let json = responses[endpoint.path] else {
            throw NetworkError.httpStatus(404)
        }
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }
}
