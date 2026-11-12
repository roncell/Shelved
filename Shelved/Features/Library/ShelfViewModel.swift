import Foundation
import Observation

/// One shelf's items, with move and remove.
@MainActor
@Observable
final class ShelfViewModel {
    let id: ShelfID
    private(set) var state: Loadable<[LibraryItem]> = .idle
    /// This shelf, for the title. Loaded alongside the items.
    private(set) var shelf: ShelfSummary?
    /// Every other shelf, for the "Move to" menu.
    private(set) var otherShelves: [ShelfSummary] = []
    var actionError: String?

    private let library: any LibraryRepository

    init(id: ShelfID, library: any LibraryRepository) {
        self.id = id
        self.library = library
    }

    /// Like the Library tab, reloads on every appearance: coming back from a
    /// book you just rated should show the new stars.
    func load() async {
        if state.value == nil { state = .loading }
        do {
            let shelves = try await library.shelves()
            guard let shelf = shelves.first(where: { $0.id == id }) else {
                throw LibraryError.shelfNotFound
            }
            self.shelf = shelf
            otherShelves = shelves.filter { $0.id != id }
            state = .loaded(try await library.items(on: id))
        } catch {
            state = .failed(error)
        }
    }

    func move(_ item: LibraryItem, to destination: ShelfID) async {
        do {
            try await library.save(item.media, to: destination)
            await load()
        } catch {
            actionError = error.userMessage
        }
    }

    func remove(_ item: LibraryItem) async {
        do {
            try await library.remove(item.id)
            await load()
        } catch {
            actionError = error.userMessage
        }
    }
}
