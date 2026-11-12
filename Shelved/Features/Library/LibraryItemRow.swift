import SwiftUI

/// A saved item: the usual media row plus your stars and progress.
struct LibraryItemRow: View {
    let item: LibraryItem

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
        switch (item.log.progress, item.log.progressTotal) {
        case let (page?, total?): String(localized: "Page \(page) of \(total)")
        case let (page?, nil): String(localized: "Page \(page)")
        default: nil
        }
    }
}

#Preview {
    let library = SwiftDataLibraryRepository.preview()
    let items = (try? library.shelves().flatMap { try library.items(on: $0.id) }) ?? []
    return List(items) { LibraryItemRow(item: $0) }
}
