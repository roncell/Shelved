import SwiftUI

struct CreatorView: View {
    let id: CreatorID
    @Environment(Router.self) private var router

    var body: some View {
        List {
            Section("Works") {
                ForEach(PlaceholderData.works(by: id)) { work in
                    Button(work.title) {
                        // Detail → Creator → Detail → … with no fixed depth.
                        router.push(.itemDetail(work.id))
                    }
                }
            }
            Section("Debug") {
                Text("Stack depth: \(router.depth)")
            }
        }
        .navigationTitle(PlaceholderData.creatorName(id))
    }
}

#Preview {
    NavigationStack {
        CreatorView(id: CreatorID(rawValue: "le-guin")).withRouteDestinations()
    }
    .environment(Router())
}
