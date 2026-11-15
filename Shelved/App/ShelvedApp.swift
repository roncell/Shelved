import SwiftUI

@main
struct ShelvedApp: App {
    /// Built once per launch. `@State` keeps the same instance for the
    /// app's lifetime even if SwiftUI re-creates this struct.
    @State private var dependencies = Dependencies.forLaunch()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(dependencies)
        }
    }
}
