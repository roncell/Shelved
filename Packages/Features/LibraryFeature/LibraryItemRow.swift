import Core
import Data
import DesignSystem
import Navigation
import SwiftUI

/// A saved item: the usual media row plus your stars and progress.
struct LibraryItemRow: View {
    /// `Core.` because SwiftUI also has a `LibraryItem` (for Xcode's
    /// library). Inside the app target our own type shadowed it; across
    /// modules the two imports tie, so the name has to say which one.
    let item: Core.LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MediaItemRow(item: item.media)
            if item.log.rating != nil || progressText != nil {
                HStack(spacing: 8) {
                    if item.log.rating != nil {
                        RatingView(rating: item.log.rating)
                    }
                    if let progressText {
                        Text(progressText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                // Line up under the title, past the 44pt cover + 12pt spacing.
                .padding(.leading, 56)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var progressText: String? {
        item.media.kind.progressText(item.log.progress, total: item.log.progressTotal)
    }
}

#Preview {
    let library = InMemoryLibraryRepository.preview()
    let items = (try? library.shelves().flatMap { try library.items(on: $0.id) }) ?? []
    return List(items) { LibraryItemRow(item: $0) }
}
