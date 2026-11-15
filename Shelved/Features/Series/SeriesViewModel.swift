import Foundation
import Observation

/// A series in reading order, joined from two sources: Wikidata says which
/// books and in what order; Open Library supplies covers and years; your
/// library supplies which shelf each one is on.
@MainActor
@Observable
final class SeriesViewModel {
    /// One line on screen: the series entry plus what we know about it.
    struct Row: Identifiable {
        let entry: SeriesEntry
        /// nil when the source has no Open Library ID for it: listed, but not openable.
        let item: MediaItem?
        /// The shelf it's on, if saved.
        let shelfName: String?

        var id: String { entry.id }
    }

    let id: SeriesID
    private(set) var state: Loadable<Series> = .idle
    private(set) var rows: [Row] = []
    var actionError: String?

    private let series: any SeriesCatalog
    private let catalog: any MediaCatalog
    private let library: any LibraryRepository
    private var items: [MediaID: MediaItem] = [:]

    init(id: SeriesID, series: any SeriesCatalog, catalog: any MediaCatalog, library: any LibraryRepository) {
        self.id = id
        self.series = series
        self.catalog = catalog
        self.library = library
    }

    /// Books that can be added and aren't in the library yet.
    var unsavedCount: Int {
        rows.filter { $0.item != nil && $0.shelfName == nil }.count
    }

    /// Coming back from a book you just shelved should update its status,
    /// without fetching the series again.
    func loadIfNeeded() async {
        if state.value != nil {
            await refreshRows()
        } else {
            await load()
        }
    }

    func load() async {
        state = .loading
        do {
            let loaded = try await series.series(id)
            // Covers and years are nice to have: without them the list still
            // works, just with titles only.
            items = (try? await catalog.items(for: loaded.linkedWorkIDs)) ?? [:]
            state = .loaded(loaded)
            await refreshRows()
        } catch {
            if Task.isCancelled {
                state = .idle
                return
            }
            state = .failed(error)
        }
    }

    /// Adds every book not already saved. Books you've saved elsewhere stay
    /// where they are: re-adding a finished book would undo its shelf.
    func addAllToWantTo() async {
        do {
            guard let wantTo = try await library.shelves().first(where: { $0.system == .wantTo }) else {
                throw LibraryError.shelfNotFound
            }
            for row in rows where row.shelfName == nil {
                if let item = row.item {
                    try await library.save(item, to: wantTo.id)
                }
            }
        } catch {
            actionError = error.userMessage
        }
        await refreshRows()
    }

    private func refreshRows() async {
        guard let loaded = state.value else { return }
        let shelves = (try? await library.shelves()) ?? []
        var built: [Row] = []
        for entry in loaded.entries {
            let item = entry.workID.map { workID in
                // Fall back to the title Wikidata gave if the catalog lookup missed.
                items[workID] ?? MediaItem(id: workID, kind: .book, title: entry.title, creators: [], coverURL: nil, year: nil)
            }
            // Look up by the item's own ID: it's the canonical one if the record was merged.
            var saved: LibraryItem?
            if let item { saved = try? await library.item(for: item.id) }
            let shelf = saved.flatMap { saved in shelves.first { $0.id == saved.shelfID } }
            built.append(Row(entry: entry, item: item, shelfName: shelf.map { $0.system?.name(for: .book) ?? $0.name }))
        }
        rows = built
    }
}
