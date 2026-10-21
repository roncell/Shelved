import SwiftUI

struct SearchView: View {
    @Environment(Router.self) private var router

    var body: some View {
        List(PlaceholderData.items) { item in
            Button {
                router.push(.itemDetail(item.id))
            } label: {
                VStack(alignment: .leading) {
                    Text(item.title).font(.headline)
                    Text(item.creatorName).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .accessibilityHint(Text("Opens details"))
        }
        .navigationTitle("Search")
    }
}

#Preview {
    NavigationStack {
        SearchView().withRouteDestinations()
    }
    .environment(Router())
}
