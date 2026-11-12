import Foundation
import Observation

@MainActor
@Observable
final class ItemDetailViewModel {
    let id: MediaID
    private(set) var state: Loadable<MediaDetail> = .idle
    /// Set if this item is in the user's library.
    private(set) var libraryItem: LibraryItem?
    /// Every shelf, for the Add to Shelf menu.
    private(set) var shelves: [ShelfSummary] = []
    /// True when the network failed and we're showing the saved snapshot.
    private(set) var isShowingSavedCopy = false
    var actionError: String?

    private let catalog: any MediaCatalog
    private let library: any LibraryRepository

    init(id: MediaID, catalog: any MediaCatalog, library: any LibraryRepository) {
        self.id = id
        self.catalog = catalog
        self.library = library
    }

    /// `.task` runs every time the screen appears, including when you come
    /// *back* from the creator or review screen. The remote detail is kept;
    /// the library part is re-read, since the review screen may have changed it.
    func loadIfNeeded() async {
        if case .loaded = state, !isShowingSavedCopy {
            await refreshLibrary()
            return
        }
        await load()
    }

    func load() async {
        state = .loading
        isShowingSavedCopy = false
        do {
            state = .loaded(try await catalog.detail(for: id))
        } catch {
            // Closed mid-load: go back to idle so the next appearance starts fresh.
            if Task.isCancelled {
                state = .idle
                return
            }
            // Offline (or Open Library is down) but the book is saved: show
            // what we have instead of an error. Local data backs up remote.
            if let saved = try? await library.item(for: id) {
                state = .loaded(MediaDetail(saved: saved.media))
                isShowingSavedCopy = true
            } else {
                state = .failed(error)
            }
        }
        await refreshLibrary()
    }

    func addToShelf(_ shelfID: ShelfID) async {
        guard let detail = state.value else { return }
        do {
            libraryItem = try await library.save(detail.item, to: shelfID)
            shelves = try await library.shelves()
        } catch {
            actionError = error.userMessage
        }
    }

    func removeFromLibrary() async {
        guard let libraryItem else { return }
        do {
            try await library.remove(libraryItem.id)
            self.libraryItem = nil
            shelves = try await library.shelves()
        } catch {
            actionError = error.userMessage
        }
    }

    private func refreshLibrary() async {
        // Look up by the loaded detail's ID: the catalog may have followed a
        // redirect, and saved items always use the canonical ID.
        let currentID = state.value?.id ?? id
        do {
            shelves = try await library.shelves()
            libraryItem = try await library.item(for: currentID)
        } catch {
            actionError = error.userMessage
        }
    }
}
