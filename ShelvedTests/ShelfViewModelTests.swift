import Foundation
import Testing
@testable import Shelved

private extension Loadable {
    var isFailed: Bool { if case .failed = self { true } else { false } }
}

@MainActor
struct ShelfViewModelTests {
    private let library = SwiftDataLibraryRepository.preview()

    /// The preview library has Dune on In Progress.
    private func inProgress() throws -> ShelfSummary {
        try #require(try library.shelves().first { $0.system == .inProgress })
    }

    @Test func loadShowsTitleItemsAndOtherShelves() async throws {
        let shelf = try inProgress()
        let viewModel = ShelfViewModel(id: shelf.id, library: library)

        await viewModel.load()

        #expect(viewModel.shelf?.name == shelf.name)
        #expect(viewModel.state.value?.map(\.media.title) == ["Dune"])
        #expect(!viewModel.otherShelves.contains { $0.id == shelf.id })
        #expect(viewModel.otherShelves.count == (try library.shelves().count) - 1)
    }

    @Test func moveTakesItemOffThisShelf() async throws {
        let viewModel = ShelfViewModel(id: try inProgress().id, library: library)
        await viewModel.load()
        let dune = try #require(viewModel.state.value?.first)
        let finished = try #require(viewModel.otherShelves.first { $0.system == .finished })

        await viewModel.move(dune, to: finished.id)

        #expect(viewModel.state.value?.isEmpty == true)
        #expect(try library.item(for: dune.id)?.shelfID == finished.id)
    }

    @Test func removeDeletesFromLibrary() async throws {
        let viewModel = ShelfViewModel(id: try inProgress().id, library: library)
        await viewModel.load()
        let dune = try #require(viewModel.state.value?.first)

        await viewModel.remove(dune)

        #expect(viewModel.state.value?.isEmpty == true)
        #expect(try library.item(for: dune.id) == nil)
    }

    /// e.g. the shelf was deleted on another screen while this one was open.
    @Test func unknownShelfFails() async {
        let viewModel = ShelfViewModel(id: ShelfID(rawValue: UUID()), library: library)

        await viewModel.load()

        #expect(viewModel.state.isFailed)
    }
}
