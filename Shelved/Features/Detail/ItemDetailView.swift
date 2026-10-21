import SwiftUI

struct ItemDetailView: View {
    let id: MediaID
    @Environment(Router.self) private var router

    var body: some View {
        let item = PlaceholderData.item(id)

        List {
            Section {
                Text(item?.title ?? id.rawValue).font(.title2.bold())
            }
            if let item {
                Section("Creator") {
                    Button(item.creatorName) {
                        router.push(.creator(item.creatorID))
                    }
                    .accessibilityHint(Text("Shows other works by this creator"))
                }
            }
            Section("Debug") {
                Text("Stack depth: \(router.depth)")
                Button("Pop to root") { router.popToRoot() }
            }
        }
        .navigationTitle(item?.title ?? "Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(id: MediaID(rawValue: "dune")).withRouteDestinations()
    }
    .environment(Router())
}
