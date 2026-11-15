import Core
import SwiftUI

package struct MediaItemRow: View {
    package let item: MediaItem

    package init(item: MediaItem) {
        self.item = item
    }

    package var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: item.coverURL, width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                if !item.creators.isEmpty {
                    Text(item.creators.map(\.name).formatted(.list(type: .and)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let year = item.year {
                    // String(year), not "\(year)" in a Text: avoids "1,965".
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        // Buttons in a List tint their labels; keep the title in the normal text color.
        .foregroundStyle(.primary)
        // VoiceOver reads the row as one element: "Dune, Frank Herbert, 1965".
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    // DesignSystem doesn't depend on Data, so no PreviewCatalog here.
    let herbert = CreatorSummary(id: .openLibraryAuthor("OL79034A"), name: "Frank Herbert")
    List {
        MediaItemRow(item: MediaItem(id: .openLibraryWork("OL893414W"), kind: .book, title: "Dune",
                                     creators: [herbert], coverURL: nil, year: 1965))
        MediaItemRow(item: MediaItem(id: .tmdbFilm(329865), kind: .film, title: "Arrival",
                                     creators: [], coverURL: nil, year: nil))
    }
}
