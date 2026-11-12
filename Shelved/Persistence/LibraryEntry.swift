import Foundation
import SwiftData

/// One saved item as stored on disk: a snapshot of the media plus the
/// user's log. Only `SwiftDataLibraryRepository` touches this class.
///
/// Uniqueness (one entry per `mediaKey`) is enforced by the repository, not
/// `@Attribute(.unique)`, because CloudKit doesn't support unique constraints.
@Model
final class LibraryEntry {
    /// `MediaID.storageKey`, e.g. "openlibrary:work:OL893414W".
    var mediaKey = ""

    // Snapshot, so shelves render offline.
    var kindRaw = MediaKind.book.rawValue
    var title = ""
    /// Parallel arrays (`CreatorID.storageKey` / name), like Open Library's own
    /// author_key / author_name. Simple types store without any custom coding.
    var creatorKeys: [String] = []
    var creatorNames: [String] = []
    var coverURL: URL?
    var year: Int?

    var shelf: Shelf?
    var addedAt = Date.now

    // The user's log.
    var ratingHalfStars: Int?
    var review: String?
    var progress: Int?
    var progressTotal: Int?
    var startedAt: Date?
    var finishedAt: Date?

    init(mediaKey: String) {
        self.mediaKey = mediaKey
    }
}
