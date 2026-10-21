import SwiftUI

struct SettingsView: View {
    var body: some View {
        PlaceholderTabView(title: "Settings", systemImage: "gearshape",
                           message: "Settings arrive in Phase 8.")
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
