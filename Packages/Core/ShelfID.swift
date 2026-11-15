import Foundation

/// Identifies a shelf, for routes like `.shelf(id)`.
///
/// Wraps our own UUID rather than SwiftData's `PersistentIdentifier`, so
/// routes and ViewModels never depend on the persistence framework.
public nonisolated struct ShelfID: Hashable, Sendable {
    public let rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
