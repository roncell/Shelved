import Foundation
import Testing
@testable import Shelved

@MainActor
struct ReviewViewModelTests {
    @Test func saveWritesTheEditedLog() async throws {
        let library = try SwiftDataLibraryRepository.inMemory()
        let item = PreviewCatalog.items[0]
        try library.save(item, to: try #require(try library.shelves().first).id)
        let viewModel = ReviewViewModel(id: item.id, library: library)
        await viewModel.loadIfNeeded()
        #expect(!viewModel.canSave)   // nothing changed yet

        viewModel.log.rating = Rating(stars: 5)
        let saved = await viewModel.save()

        #expect(saved)
        #expect(try library.item(for: item.id)?.log.rating == Rating(stars: 5))
    }

    @Test func invalidLogCannotBeSaved() async throws {
        let library = try SwiftDataLibraryRepository.inMemory()
        let item = PreviewCatalog.items[0]
        try library.save(item, to: try #require(try library.shelves().first).id)
        let viewModel = ReviewViewModel(id: item.id, library: library)
        await viewModel.loadIfNeeded()

        viewModel.log.progress = 700
        viewModel.log.progressTotal = 600

        #expect(!viewModel.canSave)
        #expect(await viewModel.save() == false)
    }
}
