import Foundation
import Testing
@testable import Core
@testable import Data
@testable import DetailFeature
@testable import Persistence

@MainActor
struct ItemDetailViewModelTests {
    private let dune = PreviewCatalog.detail

    @Test func addToShelfSavesTheLoadedItem() async throws {
        let library = try SwiftDataLibraryRepository.inMemory()
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: StubCatalog(detail: dune), series: StubSeriesCatalog(), library: library)
        await viewModel.load()
        let wantTo = try #require(viewModel.shelves.first { $0.system == .wantTo })

        await viewModel.addToShelf(wantTo.id)

        #expect(viewModel.libraryItem?.shelfID == wantTo.id)
        #expect(try library.item(for: dune.id) != nil)
    }

    /// The Phase 4 offline requirement: a saved book still opens with no network.
    @Test func offlineShowsSavedCopy() async throws {
        let library = try SwiftDataLibraryRepository.inMemory()
        let wantTo = try #require(try library.shelves().first)
        try library.save(dune.item, to: wantTo.id)
        let offline = StubCatalog(error: URLError(.notConnectedToInternet))
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: offline, series: StubSeriesCatalog(), library: library)

        await viewModel.load()

        #expect(viewModel.state.value?.title == "Dune")
        #expect(viewModel.isShowingSavedCopy)
    }

    @Test func offlineAndNotSavedShowsError() async throws {
        let offline = StubCatalog(error: URLError(.notConnectedToInternet))
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: offline, series: StubSeriesCatalog(), library: try SwiftDataLibraryRepository.inMemory())

        await viewModel.load()

        #expect(viewModel.state.value == nil)
        #expect(!viewModel.isShowingSavedCopy)
    }

    /// Returning from the review screen re-runs `.task`; the remote detail
    /// is kept and only the library part is re-read.
    @Test func comingBackDoesNotRefetchDetail() async throws {
        let spy = SpyCatalog(StubCatalog(detail: dune))
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: spy, series: StubSeriesCatalog(), library: try SwiftDataLibraryRepository.inMemory())

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(await spy.detailRequests == [dune.id])
    }

    /// A broken local store shouldn't hide a book the network loaded fine.
    @Test func libraryFailureStillShowsTheBook() async {
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: StubCatalog(detail: dune), series: StubSeriesCatalog(), library: FailingLibraryRepository())

        await viewModel.load()

        #expect(viewModel.state.value?.title == "Dune")
        #expect(viewModel.actionError != nil)
        #expect(viewModel.libraryItem == nil)
    }

    @Test func loadsSeriesMembershipForBooks() async throws {
        let membership = SeriesMembership(seriesID: .wikidata("Q6095696"), seriesName: "Dune",
                                          position: "1", total: 6, entryCount: 6)
        let viewModel = ItemDetailViewModel(
            id: dune.id, catalog: StubCatalog(detail: dune),
            series: StubSeriesCatalog(membershipResult: membership),
            library: try SwiftDataLibraryRepository.inMemory()
        )

        await viewModel.load()

        #expect(viewModel.seriesMembership?.positionText.contains("1") == true)
        #expect(viewModel.seriesMembership == membership)
    }

    /// Series are a bonus: a failed lookup hides the row, never the book.
    @Test func seriesFailureStillShowsTheBook() async throws {
        let viewModel = ItemDetailViewModel(
            id: dune.id, catalog: StubCatalog(detail: dune),
            series: StubSeriesCatalog(error: URLError(.timedOut)),
            library: try SwiftDataLibraryRepository.inMemory()
        )

        await viewModel.load()

        #expect(viewModel.state.value?.title == "Dune")
        #expect(viewModel.seriesMembership == nil)
        #expect(viewModel.actionError == nil)
    }
}
