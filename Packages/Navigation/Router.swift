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
public final class Router {
    public var path = NavigationPath()

    public init() {}

    public var depth: Int { path.count }

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }

    /// Replaces the whole stack, e.g. when handling a deep link later.
    public func setStack(_ routes: [Route]) {
        var newPath = NavigationPath()
        for route in routes { newPath.append(route) }
        path = newPath
    }
}
