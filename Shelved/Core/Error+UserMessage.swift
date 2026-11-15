import Foundation

extension Error {
    /// A short message that's safe to show a user.
    /// Raw errors ("The data couldn't be read because it is missing") are for logs, not people.
    var userMessage: String {
        if let libraryError = self as? LibraryError {
            return libraryError.message
        }
        if let catalogError = self as? CatalogError {
            return catalogError.message
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
        if case NetworkError.httpStatus(let code)? = self as? NetworkError {
            if code == 401 {
                return String(localized: "The catalog didn't accept the API token. Check Secrets.xcconfig.")
            }
            if code >= 500 {
                return String(localized: "The catalog is having trouble right now. Try again in a bit.")
            }
        }
        return String(localized: "Something went wrong. Try again.")
    }
}
