import Foundation

extension MediaID {
    /// A stable string form for storage: "openlibrary:work:OL893414W".
    ///
    /// SwiftData *can* store an enum with associated values, but `#Predicate`
    /// can't query inside one. A string can be matched exactly. The source
    /// prefix keeps catalogs apart once Phase 6 adds "tmdb:film:550".
    /// Deep links (Phase 8) can reuse the same format.
    nonisolated var storageKey: String {
        switch self {
        case .openLibraryWork(let id): "openlibrary:work:\(id)"
        }
    }

    nonisolated init?(storageKey: String) {
        let parts = storageKey.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3, !parts[2].isEmpty else { return nil }
        switch (parts[0], parts[1]) {
        case ("openlibrary", "work"): self = .openLibraryWork(parts[2])
        default: return nil
        }
    }
}
