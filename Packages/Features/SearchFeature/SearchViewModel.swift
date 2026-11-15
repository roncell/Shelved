import Core
import Data
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
    /// Bound to the scope bar (All / Books / Films / Shows).
    var scope: SearchScope = .all

    /// Everything that defines a search. The view restarts its task when
    /// this changes, so a new letter *or* a new scope starts a new search.
    struct Request: Hashable {
        let query: String
        let scope: SearchScope
    }

    var request: Request { Request(query: query, scope: scope) }

    private(set) var state: Loadable<[MediaItem]> = .idle
    private(set) var hasMorePages = false
    private(set) var isLoadingNextPage = false
    private(set) var nextPageFailed = false
    /// Set when the top book result is part of a series: "A Song of Ice
    /// and Fire" above "A Game of Thrones". Shown as a card above the results.
    private(set) var seriesSuggestion: SeriesMembership?

    private let catalog: any MediaCatalog
    private let series: any SeriesCatalog
    private let debounce: Duration

    /// The query and scope the current results belong to.
    private var activeQuery = ""
    private var activeScope: SearchScope = .all
    private var nextPage = 1

    /// `debounce` is injectable so tests can pass `.zero` and run instantly.
    init(catalog: any MediaCatalog, series: any SeriesCatalog, debounce: Duration = .milliseconds(350)) {
        self.catalog = catalog
        self.series = series
        self.debounce = debounce
    }

    /// Called by the view whenever `request` changes, via `.task(id:)`.
    ///
    /// **How debouncing works here:** each keystroke changes the task's id, so
    /// SwiftUI *cancels* the previous call and starts a new one. A cancelled
    /// `Task.sleep` throws, so only the call for the last keystroke survives
    /// the sleep and actually hits the network. No timers, no Combine.
    func searchChanged() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            reset()
            return
        }

        // `.task(id:)` also fires when the view *reappears* (e.g. coming back
        // from a detail screen). Don't throw away results and scroll position.
        if text == activeQuery, scope == activeScope, case .loaded = state { return }

        // Debounce typing only. A scope tap is one deliberate choice, so
        // waiting would just make the app feel slow.
        if text != activeQuery {
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return  // cancelled: the user kept typing
            }
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
        let scopeAtStart = activeScope
        do {
            let page = try await catalog.search(query: queryAtStart, kind: scopeAtStart.kind, page: nextPage)

            // While we were waiting, the user may have started a new search.
            // Appending this page now would mix results from two queries.
            guard queryAtStart == activeQuery, scopeAtStart == activeScope else { return }

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
        let searchScope = scope
        activeQuery = text
        activeScope = searchScope
        nextPage = 1
        hasMorePages = false
        nextPageFailed = false
        seriesSuggestion = nil
        state = .loading

        do {
            let page = try await catalog.search(query: text, kind: searchScope.kind, page: 1)
            guard text == activeQuery, searchScope == activeScope else { return }
            state = .loaded(page.items)
            hasMorePages = page.hasMore
            nextPage = 2
            await suggestSeries(for: page.items, query: text, scope: searchScope)
        } catch {
            // Cancelled because a newer search took over or the view went away:
            // not an error worth showing.
            guard !Task.isCancelled, text == activeQuery, searchScope == activeScope else { return }
            state = .failed(error)
        }
    }

    /// Only the *top* book is checked: one extra request per search, and a
    /// series card for the 9th result would be noise. Failures just mean no
    /// card; series are a bonus, never a reason to show an error.
    private func suggestSeries(for items: [MediaItem], query: String, scope: SearchScope) async {
        guard let topBook = items.prefix(3).first(where: { $0.kind == .book }) else { return }
        let membership = try? await series.membership(of: topBook)
        guard query == activeQuery, scope == activeScope, !Task.isCancelled else { return }
        seriesSuggestion = membership
    }

    private func reset() {
        seriesSuggestion = nil
        activeQuery = ""
        nextPage = 1
        hasMorePages = false
        nextPageFailed = false
        state = .idle
    }
}
