import Foundation

/// Something the user saved, as screens see it.
///
/// `media` is a snapshot taken when the item was saved. It's what makes the
/// library work offline: shelves never need the network to show titles,
/// authors, or years.
nonisolated struct LibraryItem: Identifiable, Hashable, Sendable {
    let media: MediaItem
    let shelfID: ShelfID
    let shelfName: String
    let log: ReadingLog
    let addedAt: Date

    var id: MediaID { media.id }
}
