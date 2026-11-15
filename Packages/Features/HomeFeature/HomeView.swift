import Core
import Data
import DesignSystem
import Navigation
import SwiftUI

public struct HomeView: View {
    public init() {}

    @Environment(Router.self) private var router

    public var body: some View {
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
    NavigationStack { HomeView() }
        .environment(Router())
}
