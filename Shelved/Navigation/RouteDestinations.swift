import SwiftUI

/// The single place that maps a `Route` to a screen.
///
/// Every tab's stack applies this modifier, so any screen can push any route
/// from any tab without the views knowing about each other.
struct RouteDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            switch route {
            case .itemDetail(let id):
                ItemDetailView(id: id)
            case .creator(let id):
                CreatorView(id: id)
            }
        }
    }
}

extension View {
    func withRouteDestinations() -> some View {
        modifier(RouteDestinations())
    }
}
