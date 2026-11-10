import SwiftUI

/// A book cover with a consistent 2:3 shape and a placeholder while loading.
///
/// Uses `AsyncImage` for now. It has no disk cache, so covers re-download
/// often. Swapping in a cached loader later only changes this one file.
struct CoverImage: View {
    let url: URL?
    var width: CGFloat = 44
    /// Shown while loading or when there's no image, e.g. "person.fill" for author photos.
    var placeholderSymbol = "book.closed"

    var body: some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityHidden(true)   // decorative; the title is read instead
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: placeholderSymbol).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack {
        CoverImage(url: nil)
        CoverImage(url: nil, width: 110)
        CoverImage(url: nil, width: 110, placeholderSymbol: "person.fill")
    }
}
