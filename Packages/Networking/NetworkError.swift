import Core
import Foundation

nonisolated enum NetworkError: UserFacingError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(any Error)
    /// A record kept redirecting (merged into a merged record into…).
    case tooManyRedirects

    var userFacingMessage: String? {
        guard case .httpStatus(let code) = self else { return nil }
        if code == 401 {
            return String(localized: "The catalog didn't accept the API token. Check Secrets.xcconfig.")
        }
        if code >= 500 {
            return String(localized: "The catalog is having trouble right now. Try again in a bit.")
        }
        return nil
    }
}
