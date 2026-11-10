import Foundation

extension Error {
    /// A short message that's safe to show a user.
    /// Raw errors ("The data couldn't be read because it is missing") are for logs, not people.
    var userMessage: String {
        if let urlError = self as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return String(localized: "You're offline. Check your connection and try again.")
            case .timedOut:
                return String(localized: "The request timed out. Try again.")
            default:
                break
            }
        }
        if case NetworkError.httpStatus(let code)? = self as? NetworkError, code >= 500 {
            return String(localized: "Open Library is having trouble right now. Try again in a bit.")
        }
        return String(localized: "Something went wrong. Try again.")
    }
}
