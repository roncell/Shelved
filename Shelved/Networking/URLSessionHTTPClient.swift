import Foundation

/// The real `HTTPClient`, built on `URLSession`.
nonisolated struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let headers: [String: String]

    init(session: URLSession = .shared, headers: [String: String] = [:]) {
        self.session = session
        self.headers = headers
    }

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        var request = URLRequest(url: try endpoint.makeURL())
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        // `await` suspends here without blocking any thread. If the calling
        // task is cancelled (e.g. the user typed another letter), URLSession
        // cancels the request and throws `URLError(.cancelled)`.
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
