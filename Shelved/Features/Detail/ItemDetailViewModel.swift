import Foundation
import Observation

@MainActor
@Observable
final class ItemDetailViewModel {
    let id: MediaID
    private(set) var state: Loadable<MediaDetail> = .idle

    private let catalog: any MediaCatalog

    init(id: MediaID, catalog: any MediaCatalog) {
        self.id = id
        self.catalog = catalog
    }

    /// `.task` runs every time the screen appears, including when you come
    /// *back* to it from the creator screen. Don't reload what we already have.
    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await catalog.detail(for: id))
        } catch {
            // If the screen was closed mid-load, go back to idle so the next
            // appearance starts a fresh load instead of spinning forever.
            state = Task.isCancelled ? .idle : .failed(error)
        }
    }
}
