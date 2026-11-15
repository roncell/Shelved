import Foundation

extension Error {
    /// A short message that's safe to show a user.
    /// Raw errors ("The data couldn't be read because it is missing") are for logs, not people.
    public var userMessage: String {
        if let error = self as? any UserFacingError, let message = error.userFacingMessage {
            return message
        }
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
        return String(localized: "Something went wrong. Try again.")
    }
}
