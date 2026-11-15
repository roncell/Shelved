import HomeFeature
import LibraryFeature
import Navigation
import SearchFeature
import SettingsFeature
import StatsFeature
import SwiftUI

struct RootTabView: View {
    @State private var coordinator = TabCoordinator()

    var body: some View {
        // A custom binding lets us see *every* tap, including a re-tap on the
        // current tab, which is how we trigger pop-to-root.
        let selection = Binding<AppTab>(
            get: { coordinator.selectedTab },
            set: { coordinator.select($0) }
        )

        TabView(selection: selection) {
            ForEach(AppTab.allCases) { tab in
                TabStack(tab: tab, router: coordinator.router(for: tab))
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
    }
}

/// One tab's `NavigationStack`, bound to that tab's router.
private struct TabStack: View {
    let tab: AppTab
    @Bindable var router: Router
    @Environment(Dependencies.self) private var dependencies

    var body: some View {
        NavigationStack(path: $router.path) {
            rootView
                .withRouteDestinations()
        }
        // Screens inside this stack read the router with @Environment(Router.self).
        .environment(router)
    }

    @ViewBuilder
    private var rootView: some View {
        switch tab {
        case .home: HomeView()
        case .search: SearchView(catalog: dependencies.catalog, series: dependencies.series)
        case .library: LibraryView(library: dependencies.library)
        case .stats: StatsView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    RootTabView()
        .environment(Dependencies.preview())
}
