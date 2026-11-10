import Foundation
import Testing
@testable import Shelved

private let authorID = CreatorID.openLibraryAuthor("OL79034A")

private let herbert = CreatorDetail(
    id: authorID, name: "Frank Herbert", bio: nil,
    birthDate: nil, deathDate: nil, photoURL: nil
)

private func work(_ title: String) -> MediaItem {
    MediaItem(id: .openLibraryWork(title), kind: .book, title: title,
              creators: [], coverURL: nil, year: nil)
}

private extension Loadable {
    var isFailed: Bool { if case .failed = self { true } else { false } }
}

@MainActor
struct CreatorViewModelTests {
    @Test func loadsProfileAndFirstPageOfWorks() async {
        let catalog = StubCatalog(
            creator: herbert,
            worksPages: [1: SearchPage(items: [work("Dune"), work("Dune Messiah")], hasMore: true)]
        )
        let viewModel = CreatorViewModel(id: authorID, catalog: catalog)

        await viewModel.load()

        #expect(viewModel.state.value?.name == "Frank Herbert")
        #expect(viewModel.works.value?.map(\.title) == ["Dune", "Dune Messiah"])
        #expect(viewModel.hasMoreWorks)
    }

    @Test func profileFailureFailsTheScreen() async {
        let catalog = StubCatalog(error: URLError(.notConnectedToInternet))
        let viewModel = CreatorViewModel(id: authorID, catalog: catalog)

        await viewModel.load()

        #expect(viewModel.state.isFailed)
    }

    /// The profile is still worth showing when only the works list fails.
    @Test func worksFailureKeepsProfile() async {
        let catalog = StubCatalog(creator: herbert, worksError: URLError(.timedOut))
        let viewModel = CreatorViewModel(id: authorID, catalog: catalog)

        await viewModel.load()

        #expect(viewModel.state.value?.name == "Frank Herbert")
        #expect(viewModel.works.isFailed)
    }

    @Test func nextPageAppendsAndDropsDuplicates() async {
        let catalog = StubCatalog(creator: herbert, worksPages: [
            1: SearchPage(items: [work("A"), work("B")], hasMore: true),
            2: SearchPage(items: [work("B"), work("C")], hasMore: false),
        ])
        let viewModel = CreatorViewModel(id: authorID, catalog: catalog)
        await viewModel.load()

        await viewModel.loadNextPage()

        #expect(viewModel.works.value?.map(\.title) == ["A", "B", "C"])
        #expect(!viewModel.hasMoreWorks)
    }
}
