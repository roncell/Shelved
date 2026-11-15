import SwiftUI

struct SearchView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: SearchViewModel

    /// Services come in through `init`, not the Environment, so the view
    /// can create its ViewModel right away. See `Dependencies`.
    init(catalog: any MediaCatalog, series: any SeriesCatalog) {
        _viewModel = State(initialValue: SearchViewModel(catalog: catalog, series: series))
    }

    var body: some View {
        content
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: Text("Title or name"))
            .searchScopes($viewModel.scope) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            // Restarts (and cancels the previous run) every time the query or scope changes.
            .task(id: viewModel.request) {
                await viewModel.searchChanged()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Search",
                systemImage: "magnifyingglass",
                description: Text("Find books, films and shows by title, author or director.")
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
                if let suggestion = viewModel.seriesSuggestion {
                    Section {
                        SeriesCard(membership: suggestion) {
                            router.push(.series(suggestion.seriesID))
                        }
                    }
                }
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
    let dependencies = Dependencies.preview()
    NavigationStack {
        SearchView(catalog: dependencies.catalog, series: dependencies.series).withRouteDestinations()
    }
    .environment(dependencies)
    .environment(Router())
}
