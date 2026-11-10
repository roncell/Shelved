import Foundation
import Observation

/// Owns the Search screen's state: the query, results, and paging.
///
/// Note the imports: Foundation + Observation, not SwiftUI. A ViewModel that
/// doesn't know about views is easy to unit test and could back a different UI.
@MainActor
@Observable
final class SearchViewModel {
    /// Bound to the search field.
    var query = ""

    private(set) var state: Loadable<[MediaItem]> = .idle
    private(set) var hasMorePages = false
    private(set) var isLoadingNextPage = false
    private(set) var nextPageFailed = false

    private let catalog: any MediaCatalog
    private let debounce: Duration

    /// The query the current results belong to.
    private var activeQuery = ""
    private var nextPage = 1

    /// `debounce` is injectable so tests can pass `.zero` and run instantly.
    init(catalog: any MediaCatalog, debounce: Duration = .milliseconds(350)) {
        self.catalog = catalog
        self.debounce = debounce
    }

    /// Called by the view whenever `query` changes, via `.task(id: query)`.
    ///
    /// **How debouncing works here:** each keystroke changes the task's id, so
    /// SwiftUI *cancels* the previous call and starts a new one. A cancelled
    /// `Task.sleep` throws, so only the call for the last keystroke survives
    /// the sleep and actually hits the network. No timers, no Combine.
    func queryChanged() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            reset()
            return
        }

        // `.task(id:)` also fires when the view *reappears* (e.g. coming back
        // from a detail screen). Don't throw away results and scroll position.
        if text == activeQuery, case .loaded = state { return }

        do {
            try await Task.sleep(for: debounce)
        } catch {
            return  // cancelled: the user kept typing
        }
        await runSearch(text)
    }

    /// For the "Try again" button. Skips the debounce.
    func retry() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await runSearch(text)
    }

    /// Called when the footer row at the bottom of the list appears.
    func loadNextPage() async {
        guard hasMorePages, !isLoadingNextPage, case .loaded(let current) = state else { return }

        isLoadingNextPage = true
        nextPageFailed = false
        defer { isLoadingNextPage = false }

        let queryAtStart = activeQuery
        do {
            let page = try await catalog.search(query: queryAtStart, page: nextPage)

            // While we were waiting, the user may have started a new search.
            // Appending this page now would mix results from two queries.
            guard queryAtStart == activeQuery else { return }

            // Open Library occasionally repeats a work across pages. Duplicate
            // IDs confuse `ForEach`, so drop anything we already have.
            let existing = Set(current.map(\.id))
            let newItems = page.items.filter { !existing.contains($0.id) }

            state = .loaded(current + newItems)
            hasMorePages = page.hasMore
            nextPage += 1
        } catch {
            // Keep the results already on screen. If this was a cancellation
            // (footer scrolled away), it will simply retry when it reappears.
            if !Task.isCancelled { nextPageFailed = true }
        }
    }

    private func runSearch(_ text: String) async {
        activeQuery = text
        nextPage = 1
        hasMorePages = false
        nextPageFailed = false
        state = .loading

        do {
            let page = try await catalog.search(query: text, page: 1)
            guard text == activeQuery else { return }
            state = .loaded(page.items)
            hasMorePages = page.hasMore
            nextPage = 2
        } catch {
            // Cancelled because a newer search took over or the view went away:
            // not an error worth showing.
            guard !Task.isCancelled, text == activeQuery else { return }
            state = .failed(error)
        }
    }

    private func reset() {
        activeQuery = ""
        nextPage = 1
        hasMorePages = false
        nextPageFailed = false
        state = .idle
    }
}
