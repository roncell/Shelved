import Observation

/// Every service the screens need, built once at launch and handed down
/// through the SwiftUI Environment.
///
/// This is the app's *composition root*: the one place that decides which
/// concrete types back each protocol. Screens still take their services as
/// `init` parameters (so each one states exactly what it needs); only the
/// places that create screens, `TabStack` and `RouteDestinations`, read this.
///
/// It's a class injected with `.environment(_:)`, like `Router`, so a missing
/// container fails loudly the moment a screen is pushed, instead of silently
/// falling back to a default (which is how previews used to end up writing
/// to the real library). `@Observable` is only there because that API
/// requires it; nothing here changes after launch.
@MainActor
@Observable
final class Dependencies {
    let catalog: any MediaCatalog
    let library: any LibraryRepository

    init(catalog: any MediaCatalog, library: any LibraryRepository) {
        self.catalog = catalog
        self.library = library
    }
}
