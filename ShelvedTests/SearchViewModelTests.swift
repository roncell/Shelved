import Foundation
import Testing
@testable import Shelved

private func item(_ title: String) -> MediaItem {
    MediaItem(id: .openLibraryWork(title), kind: .book, title: title,
              creators: [], coverURL: nil, year: nil)
}

private extension Loadable {
    var isIdle: Bool { if case .idle = self { true } else { false } }
    var isFailed: Bool { if case .failed = self { true } else { false } }
}

@MainActor
struct SearchViewModelTests {
    @Test func blankQueryStaysIdle() async {
        let viewModel = SearchViewModel(catalog: StubCatalog(), debounce: .zero)
        viewModel.query = "   "

        await viewModel.queryChanged()

        #expect(viewModel.state.isIdle)
    }

    @Test func searchLoadsFirstPage() async {
        let catalog = StubCatalog(pages: [1: SearchPage(items: [item("A"), item("B")], hasMore: true)])
        let viewModel = SearchViewModel(catalog: catalog, debounce: .zero)
        viewModel.query = "dune"

        await viewModel.queryChanged()

        #expect(viewModel.state.value?.map(\.title) == ["A", "B"])
        #expect(viewModel.hasMorePages)
    }

    @Test func nextPageAppendsAndDropsDuplicates() async {
        let catalog = StubCatalog(pages: [
            1: SearchPage(items: [item("A"), item("B")], hasMore: true),
            2: SearchPage(items: [item("B"), item("C")], hasMore: false),
        ])
        let viewModel = SearchViewModel(catalog: catalog, debounce: .zero)
        viewModel.query = "dune"
        await viewModel.queryChanged()

        await viewModel.loadNextPage()

        #expect(viewModel.state.value?.map(\.title) == ["A", "B", "C"])
        #expect(!viewModel.hasMorePages)
    }

    @Test func failureShowsError() async {
        let catalog = StubCatalog(error: URLError(.notConnectedToInternet))
        let viewModel = SearchViewModel(catalog: catalog, debounce: .zero)
        viewModel.query = "dune"

        await viewModel.queryChanged()

        #expect(viewModel.state.isFailed)
    }

    @Test func clearingQueryResetsToIdle() async {
        let catalog = StubCatalog(pages: [1: SearchPage(items: [item("A")], hasMore: false)])
        let viewModel = SearchViewModel(catalog: catalog, debounce: .zero)
        viewModel.query = "dune"
        await viewModel.queryChanged()

        viewModel.query = ""
        await viewModel.queryChanged()

        #expect(viewModel.state.isIdle)
    }
}
