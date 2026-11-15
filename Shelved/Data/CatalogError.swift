import Foundation

nonisolated enum CatalogError: Error, Equatable {
    /// An ID from another source reached this catalog, e.g. a TMDB film
    /// sent to Open Library. A wiring bug, since `CombinedCatalog` routes by ID.
    case unsupportedID
    /// The source needs an API key that isn't set up (see Secrets.example.xcconfig).
    case notConfigured

    var message: String {
        switch self {
        case .unsupportedID:
            String(localized: "This item comes from a catalog the app can't reach.")
        case .notConfigured:
            String(localized: "Films and shows need a TMDB API token. See Config/Secrets.example.xcconfig.")
        }
    }
}
