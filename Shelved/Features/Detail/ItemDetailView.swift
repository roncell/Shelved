import SwiftUI

struct ItemDetailView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: ItemDetailViewModel

    init(id: MediaID, catalog: any MediaCatalog = OpenLibraryCatalog()) {
        _viewModel = State(initialValue: ItemDetailViewModel(id: id, catalog: catalog))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            // Tied to the view's lifetime: popping this screen cancels the load.
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't load this book", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }

        case .loaded(let detail):
            DetailContent(detail: detail) { creatorID in
                router.push(.creator(creatorID))
            }
        }
    }
}

/// The loaded layout. Kept separate so it only deals with a `MediaDetail`,
/// not with loading states.
private struct DetailContent: View {
    let detail: MediaDetail
    let onCreatorTap: (CreatorID) -> Void

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    CoverImage(url: detail.coverURL, width: 110)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(detail.title)
                            .font(.title2.bold())
                        if let year = detail.year {
                            Text(String(year))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !detail.creators.isEmpty {
                Section("By") {
                    ForEach(detail.creators) { creator in
                        Button(creator.name) { onCreatorTap(creator.id) }
                            .accessibilityHint(Text("Shows other works by this author"))
                    }
                }
            }

            if let summary = detail.summary {
                Section("About") {
                    Text(summary)
                }
            }

            if !detail.subjects.isEmpty {
                Section("Subjects") {
                    Text(detail.subjects.formatted(.list(type: .and)))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(detail.title)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(id: .openLibraryWork("OL893415W"), catalog: PreviewCatalog())
            .withRouteDestinations()
    }
    .environment(Router())
}
