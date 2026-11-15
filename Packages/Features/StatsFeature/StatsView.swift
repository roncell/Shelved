import Core
import Data
import DesignSystem
import Navigation
import SwiftUI

public struct StatsView: View {
    public init() {}

    public var body: some View {
        PlaceholderTabView(title: "Stats", systemImage: "chart.bar",
                           message: "Charts arrive in Phase 8.")
    }
}

#Preview {
    NavigationStack { StatsView() }
}
