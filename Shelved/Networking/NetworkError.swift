import Foundation

nonisolated enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(any Error)
}
