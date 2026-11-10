import Foundation

/// Sends an `Endpoint` and decodes its response.
///
/// A protocol so tests can swap in a fake that returns canned JSON
/// without touching the network.
nonisolated protocol HTTPClient: Sendable {
    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response
}
