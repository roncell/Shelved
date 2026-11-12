import Foundation

/// Identifies a shelf, for routes like `.shelf(id)`.
///
/// Wraps our own UUID rather than SwiftData's `PersistentIdentifier`, so
/// routes and ViewModels never depend on the persistence framework.
nonisolated struct ShelfID: Hashable, Sendable {
    let rawValue: UUID
}
