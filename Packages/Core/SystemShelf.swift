import Foundation

/// The built-in shelves every library has. Users can add their own on top.
///
/// Display names come from here, not from the database, so they're
/// localized and can change without a data migration. Only the raw value
/// is stored.
public nonisolated enum SystemShelf: String, CaseIterable, Sendable {
    case wantTo, inProgress, finished

    /// The name in the Library tab, where shelves hold every kind of item.
    public var name: String { name(for: nil) }

    /// The name next to one item: a film's menu says "Want to Watch".
    public func name(for kind: MediaKind?) -> String {
        switch (self, kind) {
        case (.wantTo, .book): String(localized: "Want to Read")
        case (.wantTo, .film), (.wantTo, .show): String(localized: "Want to Watch")
        case (.wantTo, nil): String(localized: "Want to Read/Watch")
        case (.inProgress, _): String(localized: "In Progress")
        case (.finished, _): String(localized: "Finished")
        }
    }

    /// Every name this shelf can appear under, so a custom shelf can't
    /// reuse any of them.
    public var allNames: [String] {
        [name(for: nil), name(for: .book), name(for: .film)]
    }

    public var systemImage: String {
        switch self {
        case .wantTo: "bookmark"
        case .inProgress: "book"
        case .finished: "checkmark.circle"
        }
    }
}
