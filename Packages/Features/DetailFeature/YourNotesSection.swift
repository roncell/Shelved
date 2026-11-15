import Core
import Data
import DesignSystem
import Navigation
import SwiftUI

/// Your rating, progress, dates, and review for a saved item, with a way to edit them.
struct YourNotesSection: View {
    let item: Core.LibraryItem
    let onEdit: () -> Void

    private var log: ReadingLog { item.log }

    var body: some View {
        Section("Your Notes") {
            if log.isEmpty {
                Button("Rate, review, or add notes", systemImage: "square.and.pencil", action: onEdit)
            } else {
                if log.rating != nil {
                    RatingView(rating: log.rating, size: .body)
                }
                if let progress = item.media.kind.progressText(log.progress, total: log.progressTotal) {
                    LabeledContent("Progress", value: progress)
                }
                if let startedAt = log.startedAt {
                    LabeledContent("Started", value: startedAt, format: .dateTime.day().month().year())
                }
                if let finishedAt = log.finishedAt {
                    LabeledContent("Finished", value: finishedAt, format: .dateTime.day().month().year())
                }
                if !log.review.isEmpty {
                    ExpandableText(log.review, collapsedLineLimit: 4)
                }
                Button("Edit", systemImage: "square.and.pencil", action: onEdit)
            }
        }
    }
}

#Preview {
    let library = InMemoryLibraryRepository.preview()
    let saved = try? library.item(for: PreviewCatalog.items[0].id)
    return List {
        if let saved {
            YourNotesSection(item: saved) {}
        }
    }
}
