import Foundation
import Testing
@testable import Core
@testable import Data
@testable import SearchFeature

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
        let viewModel = SearchViewModel(catalog: StubCatalog(), series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "   "

        await viewModel.searchChanged()

        #expect(viewModel.state.isIdle)
    }

    @Test func searchLoadsFirstPage() async {
        let catalog = StubCatalog(pages: [1: SearchPage(items: [item("A"), item("B")], hasMore: true)])
        let viewModel = SearchViewModel(catalog: catalog, series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "dune"

        await viewModel.searchChanged()

        #expect(viewModel.state.value?.map(\.title) == ["A", "B"])
        #expect(viewModel.hasMorePages)
    }

    @Test func nextPageAppendsAndDropsDuplicates() async {
        let catalog = StubCatalog(pages: [
            1: SearchPage(items: [item("A"), item("B")], hasMore: true),
            2: SearchPage(items: [item("B"), item("C")], hasMore: false),
        ])
        let viewModel = SearchViewModel(catalog: catalog, series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "dune"
        await viewModel.searchChanged()

        await viewModel.loadNextPage()

        #expect(viewModel.state.value?.map(\.title) == ["A", "B", "C"])
        #expect(!viewModel.hasMorePages)
    }

    @Test func failureShowsError() async {
        let catalog = StubCatalog(error: URLError(.notConnectedToInternet))
        let viewModel = SearchViewModel(catalog: catalog, series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "dune"

        await viewModel.searchChanged()

        #expect(viewModel.state.isFailed)
    }

    @Test func clearingQueryResetsToIdle() async {
        let catalog = StubCatalog(pages: [1: SearchPage(items: [item("A")], hasMore: false)])
        let viewModel = SearchViewModel(catalog: catalog, series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "dune"
        await viewModel.searchChanged()

        viewModel.query = ""
        await viewModel.searchChanged()

        #expect(viewModel.state.isIdle)
    }

    // MARK: - Spy tests: *how* the catalog is called

    /// Mirrors what `.task(id: query)` does on each keystroke: the previous
    /// call is cancelled while it waits out the debounce.
    @Test func typingFastSearchesOnlyTheLastQuery() async {
        let spy = SpyCatalog(StubCatalog(pages: [1: SearchPage(items: [item("A")], hasMore: false)]))
        let viewModel = SearchViewModel(catalog: spy, series: StubSeriesCatalog(), debounce: .milliseconds(50))

        viewModel.query = "du"
        let firstKeystroke = Task { await viewModel.searchChanged() }
        firstKeystroke.cancel()
        viewModel.query = "dune"
        await viewModel.searchChanged()
        await firstKeystroke.value

        #expect(await spy.searches == [SpyCatalog.SearchCall(query: "dune", page: 1)])
    }

    @Test func nextPageAsksForPageTwoOfTheSameQuery() async {
        let spy = SpyCatalog(StubCatalog(pages: [
            1: SearchPage(items: [item("A")], hasMore: true),
            2: SearchPage(items: [item("B")], hasMore: false),
        ]))
        let viewModel = SearchViewModel(catalog: spy, series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "dune"
        await viewModel.searchChanged()

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()   // no more pages: must not call again

        #expect(await spy.searches.map(\.page) == [1, 2])
        #expect(await spy.searches.allSatisfy { $0.query == "dune" })
    }

    /// Coming back from a detail screen re-runs `.task(id:)` with the same query.
    @Test func reappearingDoesNotSearchAgain() async {
        let spy = SpyCatalog(StubCatalog(pages: [1: SearchPage(items: [item("A")], hasMore: false)]))
        let viewModel = SearchViewModel(catalog: spy, series: StubSeriesCatalog(), debounce: .zero)
        viewModel.query = "dune"
        await viewModel.searchChanged()

        await viewModel.searchChanged()

        #expect(await spy.searches.count == 1)
    }

    /// A scope tap searches straight away with the new kind: no debounce.
    @Test func changingScopeSearchesThatKind() async {
        let spy = SpyCatalog(StubCatalog(pages: [1: SearchPage(items: [item("A")], hasMore: false)]))
        let viewModel = SearchViewModel(catalog: spy, series: StubSeriesCatalog(), debounce: .seconds(60))
        viewModel.query = "arrival"
        viewModel.scope = .films
        await viewModel.retry()                 // results for "arrival" in Films, skipping the debounce

        viewModel.scope = .shows
        await viewModel.searchChanged()         // would hang for 60s if it debounced

        #expect(await spy.searches.map(\.kind) == [.film, .show])
    }

    // MARK: - Series card

    @Test func topBookInASeriesShowsTheCard() async {
        let membership = SeriesMembership(seriesID: .wikidata("Q45875"), seriesName: "A Song of Ice and Fire",
                                          position: "1", total: 5, entryCount: 7)
        let viewModel = SearchViewModel(
            catalog: StubCatalog(pages: [1: SearchPage(items: [item("A Game of Thrones")], hasMore: false)]),
            series: StubSeriesCatalog(membershipResult: membership),
            debounce: .zero
        )
        viewModel.query = "game of thrones"

        await viewModel.searchChanged()

        #expect(viewModel.seriesSuggestion == membership)
    }

    @Test func newSearchClearsTheCard() async {
        let membership = SeriesMembership(seriesID: .wikidata("Q1"), seriesName: "S", position: "1", total: nil, entryCount: 2)
        let viewModel = SearchViewModel(
            catalog: StubCatalog(pages: [1: SearchPage(items: [item("A")], hasMore: false)]),
            series: StubSeriesCatalog(membershipResult: membership),
            debounce: .zero
        )
        viewModel.query = "a"
        await viewModel.searchChanged()

        viewModel.query = ""
        await viewModel.searchChanged()

        #expect(viewModel.seriesSuggestion == nil)
    }
}
