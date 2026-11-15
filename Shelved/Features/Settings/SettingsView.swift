import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Settings arrive in Phase 8.")
                    .foregroundStyle(.secondary)
            }
            Section("Data Sources") {
                Text("Book data from Open Library.")
                // TMDB's terms require this notice in apps that use its API.
                Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
