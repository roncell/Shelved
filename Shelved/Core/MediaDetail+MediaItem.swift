import Foundation

extension MediaDetail {
    /// The list-sized version of this detail, e.g. to save to a shelf.
    nonisolated var item: MediaItem {
        MediaItem(id: id, kind: kind, title: title, creators: creators, coverURL: coverURL, year: year)
    }

    /// A detail built from a saved snapshot, for when the network isn't
    /// available. Fields only the API has (summary, subjects…) are empty.
    nonisolated init(saved item: MediaItem) {
        self.init(
            id: item.id, kind: item.kind, title: item.title, creators: item.creators,
            coverURL: item.coverURL, year: item.year, summary: nil,
            subjects: [], places: [], characters: [], timePeriods: [], links: []
        )
    }
}
