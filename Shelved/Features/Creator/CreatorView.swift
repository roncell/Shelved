import SwiftUI

/// Placeholder until Phase 3, which loads the author and their other works.
struct CreatorView: View {
    let id: CreatorID

    var body: some View {
        ContentUnavailableView(
            "Author pages arrive in Phase 3",
            systemImage: "person.crop.circle",
            description: Text("This screen will list the author's other works.")
        )
        .navigationTitle("Author")
    }
}

#Preview {
    NavigationStack {
        CreatorView(id: .openLibraryAuthor("OL79034A"))
    }
}
