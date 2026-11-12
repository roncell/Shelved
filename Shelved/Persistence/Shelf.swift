import Foundation
import SwiftData

/// A shelf as stored on disk. Only `SwiftDataLibraryRepository` touches this
/// class; everything else sees `ShelfSummary`.
///
/// Every property has a default and the relationship is optional. SwiftData
/// alone doesn't require that, but CloudKit sync (a stretch goal) does, and
/// changing a stored model later means writing a migration.
@Model
final class Shelf {
    /// Our own ID (not `persistentModelID`) so routes can carry it as a `ShelfID`.
    var shelfID = UUID()
    /// Only used for custom shelves; system shelves take their name from `SystemShelf`.
    var name = ""
    /// `SystemShelf.rawValue` for built-in shelves, nil for the user's own.
    var systemKind: String?
    var sortOrder = 0

    /// `.nullify`: deleting a shelf never deletes entries. The repository
    /// moves them to Want to Read first.
    @Relationship(deleteRule: .nullify, inverse: \LibraryEntry.shelf)
    var entries: [LibraryEntry]? = []

    init(name: String, system: SystemShelf?, sortOrder: Int) {
        self.name = name
        self.systemKind = system?.rawValue
        self.sortOrder = sortOrder
    }
}
