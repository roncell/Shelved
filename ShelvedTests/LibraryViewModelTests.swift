import Foundation
import Testing
@testable import Shelved

private extension Loadable {
    var isFailed: Bool { if case .failed = self { true } else { false } }
}

@MainActor
struct LibraryViewModelTests {
    @Test func loadSplitsBuiltInAndCustomShelves() async {
        let viewModel = LibraryViewModel(library: SwiftDataLibraryRepository.preview())

        await viewModel.load()

        #expect(viewModel.systemShelves.compactMap(\.system) == SystemShelf.allCases)
        #expect(viewModel.customShelves.map(\.name) == ["Book Club"])
    }

    @Test func createShelfShowsItInTheList() async throws {
        let viewModel = LibraryViewModel(library: try SwiftDataLibraryRepository.inMemory())
        await viewModel.load()

        await viewModel.createShelf(named: "Summer 2026")

        #expect(viewModel.customShelves.map(\.name) == ["Summer 2026"])
        #expect(viewModel.actionError == nil)
    }

    @Test func duplicateNameShowsAnError() async {
        let viewModel = LibraryViewModel(library: SwiftDataLibraryRepository.preview())
        await viewModel.load()

        await viewModel.createShelf(named: "book club")

        #expect(viewModel.actionError == LibraryError.duplicateShelfName.message)
        #expect(viewModel.customShelves.count == 1)
    }

    @Test func deleteShelfRemovesIt() async throws {
        let viewModel = LibraryViewModel(library: SwiftDataLibraryRepository.preview())
        await viewModel.load()
        let bookClub = try #require(viewModel.customShelves.first)

        await viewModel.deleteShelf(bookClub)

        #expect(viewModel.customShelves.isEmpty)
    }

    @Test func storeFailureShowsError() async {
        let viewModel = LibraryViewModel(library: FailingLibraryRepository())

        await viewModel.load()

        #expect(viewModel.state.isFailed)
    }
}
