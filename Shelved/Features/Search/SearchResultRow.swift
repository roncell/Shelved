import SwiftUI

struct SearchResultRow: View {
    let item: MediaItem

    var body: some View {
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
    List(PreviewCatalog.items) { SearchResultRow(item: $0) }
}
