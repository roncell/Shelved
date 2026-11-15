import Foundation

/// Something the user saved, as screens see it.
///
/// `media` is a snapshot taken when the item was saved. It's what makes the
/// library work offline: shelves never need the network to show titles,
/// authors, or years.
public nonisolated struct LibraryItem: Identifiable, Hashable, Sendable {
    public let media: MediaItem
    public let shelfID: ShelfID
    public let shelfName: String
    public let log: ReadingLog
    public let addedAt: Date

    public init(media: MediaItem, shelfID: ShelfID, shelfName: String, log: ReadingLog, addedAt: Date) {
        self.media = media
        self.shelfID = shelfID
        self.shelfName = shelfName
        self.log = log
        self.addedAt = addedAt
    }

    public var id: MediaID { media.id }
}
