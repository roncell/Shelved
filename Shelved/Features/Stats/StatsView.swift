import SwiftUI

struct StatsView: View {
    var body: some View {
        PlaceholderTabView(title: "Stats", systemImage: "chart.bar",
                           message: "Charts arrive in Phase 8.")
    }
}

#Preview {
    NavigationStack { StatsView() }
}
