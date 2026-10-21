import SwiftUI

struct LibraryView: View {
    var body: some View {
        PlaceholderTabView(title: "Library", systemImage: "books.vertical",
                           message: "Your shelves arrive in Phase 4.")
    }
}

#Preview {
    NavigationStack { LibraryView() }
}
