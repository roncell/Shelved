import SwiftUI

/// Stand-in content for tabs that get built in later phases.
struct PlaceholderTabView: View {
    let title: LocalizedStringResource
    let systemImage: String
    let message: LocalizedStringResource

    var body: some View {
        ContentUnavailableView {
            Label { Text(title) } icon: { Image(systemName: systemImage) }
        } description: {
            Text(message)
        }
        .navigationTitle(Text(title))
    }
}
