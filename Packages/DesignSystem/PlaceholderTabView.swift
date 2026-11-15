import Core
import SwiftUI

/// Stand-in content for tabs that get built in later phases.
package struct PlaceholderTabView: View {
    package let title: LocalizedStringResource
    package let systemImage: String
    package let message: LocalizedStringResource

    package init(title: LocalizedStringResource, systemImage: String, message: LocalizedStringResource) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
    }

    package var body: some View {
        ContentUnavailableView {
            Label { Text(title) } icon: { Image(systemName: systemImage) }
        } description: {
            Text(message)
        }
        .navigationTitle(Text(title))
    }
}
