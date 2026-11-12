import Foundation
import Observation

/// The Library tab: every shelf with its item count.
@MainActor
@Observable
final class LibraryViewModel {
    private(set) var state: Loadable<[ShelfSummary]> = .idle
    /// Set when an action (create/delete) fails; the view shows it in an alert.
    var actionError: String?

    private let library: any LibraryRepository

    init(library: any LibraryRepository) {
        self.library = library
    }

    var systemShelves: [ShelfSummary] { state.value?.filter(\.isSystem) ?? [] }
    var customShelves: [ShelfSummary] { state.value?.filter { !$0.isSystem } ?? [] }

    /// Runs every time the tab appears, unlike the network screens'
    /// `loadIfNeeded`. Items may have been added from Search or Detail since
    /// we last looked, and a local fetch is cheap enough to just redo.
    ///
    /// (`@Query` would refresh automatically, but it only works inside views,
    /// which would put SwiftData back in the UI layer. That's the trade-off.)
    func load() async {
        // Only show a spinner the first time; after that, refresh in place.
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await library.shelves())
        } catch {
            state = .failed(error)
        }
    }

    func createShelf(named name: String) async {
        do {
            _ = try await library.createShelf(named: name)
            await load()
        } catch {
            actionError = error.userMessage
        }
    }

    func deleteShelf(_ shelf: ShelfSummary) async {
        do {
            try await library.deleteShelf(shelf.id)
            await load()
        } catch {
            actionError = error.userMessage
        }
    }
}
