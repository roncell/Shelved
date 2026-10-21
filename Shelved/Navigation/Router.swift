import SwiftUI

/// Owns the navigation stack for one tab.
///
/// Why a router instead of `NavigationLink(destination:)`?
/// - Navigation becomes *state* you can read, test, and change from code
///   (deep links, pop-to-root, "dismiss after save").
/// - Views don't need to know how to build the next screen; they just say
///   `router.push(.creator(id))`.
@MainActor
@Observable
final class Router {
    var path = NavigationPath()

    var depth: Int { path.count }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }

    /// Replaces the whole stack, e.g. when handling a deep link later.
    func setStack(_ routes: [Route]) {
        var newPath = NavigationPath()
        for route in routes { newPath.append(route) }
        path = newPath
    }
}
