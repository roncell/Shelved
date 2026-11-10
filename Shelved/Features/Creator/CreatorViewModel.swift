import Foundation
import Observation

/// Owns the creator screen: the profile, plus a paged list of their works.
///
/// The route only carries a `CreatorID`. This screen loads everything else
/// itself, so it works the same whether you arrive from a book, a deep link,
/// or the fifth level of a detail → creator → detail chain.
@MainActor
@Observable
final class CreatorViewModel {
    let id: CreatorID

    /// The profile. If this fails, the whole screen shows an error.
    private(set) var state: Loadable<CreatorDetail> = .idle
    /// Works load separately: if they fail, the profile still shows, with an
    /// inline "Try Again" for just this section.
    private(set) var works: Loadable<[MediaItem]> = .idle
    private(set) var hasMoreWorks = false
    private(set) var isLoadingNextPage = false
    private(set) var nextPageFailed = false

    private let catalog: any MediaCatalog
    private var nextPage = 1

    init(id: CreatorID, catalog: any MediaCatalog) {
        self.id = id
        self.catalog = catalog
    }

    /// `.task` re-runs when you come back from a book. Keep what's loaded.
    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    func load() async {
        state = .loading
        works = .loading

        // `async let` starts both requests *now* and runs them in parallel;
        // `await` below only waits for results. Two requests, one round-trip.
        //
        // Compare the task group in `OpenLibraryCatalog.authors(for:)`:
        // `async let` suits a fixed number of differently typed calls,
        // a task group suits "N of the same thing".
        async let profile = catalog.creator(for: id)
        async let firstPage = catalog.works(by: id, page: 1)

        do {
            state = .loaded(try await profile)
        } catch {
            // Returning here leaves `firstPage` un-awaited. Swift cancels it
            // and waits for it automatically: an `async let` can't outlive
            // the scope that started it. That's structured concurrency.
            resetIfCancelled(else: { state = .failed(error) })
            return
        }

        do {
            applyFirstPage(try await firstPage)
        } catch {
            resetIfCancelled(else: { works = .failed(error) })
        }
    }

    /// For the works section's "Try Again" button.
    func retryWorks() async {
        works = .loading
        do {
            applyFirstPage(try await catalog.works(by: id, page: 1))
        } catch {
            if !Task.isCancelled { works = .failed(error) }
        }
    }

    /// Called when the footer row at the bottom of the works list appears.
    func loadNextPage() async {
        guard hasMoreWorks, !isLoadingNextPage, case .loaded(let current) = works else { return }

        isLoadingNextPage = true
        nextPageFailed = false
        defer { isLoadingNextPage = false }

        do {
            let page = try await catalog.works(by: id, page: nextPage)
            // Search results can repeat a work across pages; drop duplicates
            // so `ForEach` IDs stay unique (same rule as SearchViewModel).
            let existing = Set(current.map(\.id))
            works = .loaded(current + page.items.filter { !existing.contains($0.id) })
            hasMoreWorks = page.hasMore
            nextPage += 1
        } catch {
            if !Task.isCancelled { nextPageFailed = true }
        }
    }

    private func applyFirstPage(_ page: SearchPage) {
        works = .loaded(page.items)
        hasMoreWorks = page.hasMore
        nextPageFailed = false
        nextPage = 2
    }

    /// Leaving the screen mid-load cancels the task. That isn't an error:
    /// go back to idle so the next appearance starts a fresh load.
    private func resetIfCancelled(else fail: () -> Void) {
        if Task.isCancelled {
            state = .idle
            works = .idle
        } else {
            fail()
        }
    }
}
