import Foundation

/// The kind filter under the search field.
enum SearchScope: String, CaseIterable, Identifiable, Hashable {
    case all, books, films, shows

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .all: "All"
        case .books: "Books"
        case .films: "Films"
        case .shows: "Shows"
        }
    }

    /// What the catalog is asked for. nil means every kind.
    var kind: MediaKind? {
        switch self {
        case .all: nil
        case .books: .book
        case .films: .film
        case .shows: .show
        }
    }
}
