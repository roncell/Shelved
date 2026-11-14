import Foundation

/// The built-in shelves every library has. Users can add their own on top.
///
/// Display names come from here, not from the database, so they're
/// localized and can change (e.g. "Want to Watch" in Phase 6) without a
/// data migration. Only the raw value is stored.
nonisolated enum SystemShelf: String, CaseIterable, Sendable {
    case wantTo, inProgress, finished

    var name: String {
        switch self {
        case .wantTo: String(localized: "Want to Read")
        case .inProgress: String(localized: "In Progress")
        case .finished: String(localized: "Finished")
        }
    }

    var systemImage: String {
        switch self {
        case .wantTo: "bookmark"
        case .inProgress: "book"
        case .finished: "checkmark.circle"
        }
    }
}
