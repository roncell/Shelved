import SwiftUI

struct SearchView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: SearchViewModel

    /// The catalog is passed in so previews can use fake data.
    /// Phase 5 replaces this with a dependency container in the Environment.
    init(catalog: any MediaCatalog = OpenLibraryCatalog()) {
        _viewModel = State(initialValue: SearchViewModel(catalog: catalog))
    }

    var body: some View {
        content
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: Text("Title or author"))
            // Restarts (and cancels the previous run) every time the query changes.
            .task(id: viewModel.query) {
                await viewModel.queryChanged()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Search Open Library",
                systemImage: "magnifyingglass",
                description: Text("Find books by title or author.")
            )

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't load results", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.retry() }
                }
            }

        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView.search(text: viewModel.query)

        case .loaded(let items):
            List {
                ForEach(items) { item in
                    Button {
                        router.push(.itemDetail(item.id))
                    } label: {
                        MediaItemRow(item: item)
                    }
                    .accessibilityHint(Text("Opens details"))
                }
                if viewModel.hasMorePages {
                    LoadMoreFooter(trigger: items.count, failed: viewModel.nextPageFailed) {
                        await viewModel.loadNextPage()
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(catalog: PreviewCatalog()).withRouteDestinations()
    }
    .environment(Router())
}
