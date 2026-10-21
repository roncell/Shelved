import SwiftUI

/// Owns which tab is selected plus one `Router` per tab.
///
/// Each tab keeps its own stack, so switching from Search (3 screens deep)
/// to Library and back leaves you where you were — the behavior users expect.
@MainActor
@Observable
final class TabCoordinator {
    private(set) var selectedTab: AppTab = .home
    private let routers: [AppTab: Router]

    init() {
        var routers: [AppTab: Router] = [:]
        for tab in AppTab.allCases { routers[tab] = Router() }
        self.routers = routers
    }

    func router(for tab: AppTab) -> Router {
        // Every case is created in init, so this lookup always succeeds.
        // A fallback keeps us free of force unwraps.
        routers[tab] ?? Router()
    }

    /// Called whenever the user taps a tab, including the one already selected.
    func select(_ tab: AppTab) {
        if tab == selectedTab {
            router(for: tab).popToRoot()
        }
        selectedTab = tab
    }
}
