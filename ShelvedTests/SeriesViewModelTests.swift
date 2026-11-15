import Foundation
import Testing
@testable import Core
@testable import Data
@testable import Persistence
@testable import SeriesFeature

private let duneID = MediaID.openLibraryWork("OL893414W")
private let messiahID = MediaID.openLibraryWork("OL893461W")

private let series = Series(id: .wikidata("Q6095696"), name: "Dune", entries: [
    SeriesEntry(position: "1", sortKey: 1, title: "Dune", workID: duneID),
    SeriesEntry(position: "2", sortKey: 2, title: "Dune Messiah", workID: messiahID),
    SeriesEntry(position: "3", sortKey: 3, title: "Children of Dune", workID: nil),
])

private let messiah = MediaItem(id: messiahID, kind: .book, title: "Dune Messiah", creators: [],
                                coverURL: URL(string: "https://covers.openlibrary.org/b/id/2-M.jpg"), year: 1969)

@MainActor
struct SeriesViewModelTests {
    private func makeViewModel(library: any LibraryRepository) -> SeriesViewModel {
        SeriesViewModel(
            id: series.id,
            series: StubSeriesCatalog(seriesResult: series),
            catalog: StubCatalog(items: [messiahID: messiah]),   // Dune's cover lookup "missed"
            library: library
        )
    }

    @Test func rowsJoinSeriesCatalogAndLibrary() async throws {
        let library = InMemoryLibraryRepository.preview()   // Dune is on In Progress
        let viewModel = makeViewModel(library: library)

        await viewModel.load()

        #expect(viewModel.rows.map(\.entry.title) == ["Dune", "Dune Messiah", "Children of Dune"])
        #expect(viewModel.rows[0].item?.title == "Dune")             // fell back to the series title
        #expect(viewModel.rows[0].shelfName == "In Progress")
        #expect(viewModel.rows[1].item?.coverURL != nil)              // from the catalog
        #expect(viewModel.rows[1].shelfName == nil)
        #expect(viewModel.rows[2].item == nil)                        // no Open Library ID
        #expect(viewModel.unsavedCount == 1)
    }

    /// Dune is already In Progress; adding the series mustn't move it back.
    @Test func addAllOnlyAddsUnsavedBooks() async throws {
        let library = InMemoryLibraryRepository.preview()
        let viewModel = makeViewModel(library: library)
        await viewModel.load()

        await viewModel.addAllToWantTo()

        let wantTo = try #require(try library.shelves().first { $0.system == .wantTo })
        #expect(try library.item(for: messiahID)?.shelfID == wantTo.id)
        #expect(try library.item(for: duneID)?.shelfID != wantTo.id)
        #expect(viewModel.unsavedCount == 0)
        #expect(viewModel.rows[1].shelfName == "Want to Read")
    }

    @Test func seriesFailureShowsError() async throws {
        let viewModel = SeriesViewModel(
            id: series.id, series: StubSeriesCatalog(error: URLError(.notConnectedToInternet)),
            catalog: StubCatalog(), library: try SwiftDataLibraryRepository.inMemory()
        )

        await viewModel.load()

        #expect(viewModel.state.value == nil)
        #expect(viewModel.rows.isEmpty)
    }
}
