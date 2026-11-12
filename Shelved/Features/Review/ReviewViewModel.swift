import Foundation
import Observation

/// Edits the rating, review, progress, and dates for one saved item.
@MainActor
@Observable
final class ReviewViewModel {
    let id: MediaID
    /// The saved item, for the title and as the "before" for change detection.
    private(set) var state: Loadable<LibraryItem> = .idle
    /// The working copy the form binds to. Saved only on `save()`.
    var log = ReadingLog()
    var saveError: String?

    private let library: any LibraryRepository

    init(id: MediaID, library: any LibraryRepository) {
        self.id = id
        self.library = library
    }

    var hasChanges: Bool { log != state.value?.log }
    var canSave: Bool { hasChanges && log.validationErrors.isEmpty }

    /// Loads once. Reloading on reappear would wipe the user's unsaved edits.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        do {
            guard let item = try await library.item(for: id) else { throw LibraryError.itemNotFound }
            log = item.log
            state = .loaded(item)
        } catch {
            state = .failed(error)
        }
    }

    /// Returns true when saved, so the view knows to close.
    func save() async -> Bool {
        guard canSave else { return false }
        do {
            try await library.updateLog(log, for: id)
            return true
        } catch {
            saveError = error.userMessage
            return false
        }
    }
}
