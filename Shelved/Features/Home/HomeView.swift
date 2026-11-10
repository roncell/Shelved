import SwiftUI

struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        List {
            Section("Currently reading") {
                // A real Open Library work ID. Replaced by your library in Phase 4/8.
                Button("Dune") { router.push(.itemDetail(.openLibraryWork("OL893414W"))) }
            }
        }
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack { HomeView().withRouteDestinations() }
        .environment(Router())
}
