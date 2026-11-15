import SwiftUI

/// The single place that maps a `Route` to a screen.
///
/// Every tab's stack applies this modifier, so any screen can push any route
/// from any tab without the views knowing about each other. It's also where
/// pushed screens get their services, from the `Dependencies` container.
struct RouteDestinations: ViewModifier {
    @Environment(Dependencies.self) private var dependencies

    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            switch route {
            case .itemDetail(let id):
                ItemDetailView(id: id, catalog: dependencies.catalog, series: dependencies.series, library: dependencies.library)
            case .creator(let id):
                CreatorView(id: id, catalog: dependencies.catalog)
            case .series(let id):
                SeriesView(id: id, series: dependencies.series, catalog: dependencies.catalog, library: dependencies.library)
            case .shelf(let id):
                ShelfView(id: id, library: dependencies.library)
            case .review(let id):
                ReviewView(id: id, library: dependencies.library)
            }
        }
    }
}

extension View {
    func withRouteDestinations() -> some View {
        modifier(RouteDestinations())
    }
}
