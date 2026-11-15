import Core
import Foundation

public nonisolated enum CatalogError: UserFacingError, Equatable {
    /// An ID from another source reached this catalog, e.g. a TMDB film
    /// sent to Open Library. A wiring bug, since `CombinedCatalog` routes by ID.
    case unsupportedID
    /// The source needs an API key that isn't set up (see Secrets.example.xcconfig).
    case notConfigured

    public var userFacingMessage: String? { message }

    public var message: String {
        switch self {
        case .unsupportedID:
            String(localized: "This item comes from a catalog the app can't reach.")
        case .notConfigured:
            String(localized: "Films and shows need a TMDB API token. See Config/Secrets.example.xcconfig.")
        }
    }
}
