import SwiftUI

struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        List {
            Section("Currently reading") {
                // Proves Home can push the same routes Search does.
                Button("Dune") { router.push(.itemDetail(MediaID(rawValue: "dune"))) }
            }
        }
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack { HomeView().withRouteDestinations() }
        .environment(Router())
}
