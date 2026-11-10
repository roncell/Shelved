import Foundation

nonisolated enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(any Error)
    /// A record kept redirecting (merged into a merged record into…).
    case tooManyRedirects
}
