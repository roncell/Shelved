import Foundation
import Testing
@testable import Shelved

@MainActor
struct ItemDetailViewModelTests {
    private let dune = PreviewCatalog.detail

    @Test func addToShelfSavesTheLoadedItem() async throws {
        let library = try SwiftDataLibraryRepository.inMemory()
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: StubCatalog(detail: dune), library: library)
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
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: offline, library: library)

        await viewModel.load()

        #expect(viewModel.state.value?.title == "Dune")
        #expect(viewModel.isShowingSavedCopy)
    }

    @Test func offlineAndNotSavedShowsError() async throws {
        let offline = StubCatalog(error: URLError(.notConnectedToInternet))
        let viewModel = ItemDetailViewModel(id: dune.id, catalog: offline, library: try SwiftDataLibraryRepository.inMemory())

        await viewModel.load()

        #expect(viewModel.state.value == nil)
        #expect(!viewModel.isShowingSavedCopy)
    }
}
