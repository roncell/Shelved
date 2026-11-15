import Foundation

extension MediaID {
    /// A stable string form for storage: "openlibrary:work:OL893414W".
    ///
    /// SwiftData *can* store an enum with associated values, but `#Predicate`
    /// can't query inside one. A string can be matched exactly. The source
    /// prefix keeps catalogs apart: "tmdb:film:550", "tmdb:show:1399".
    /// Deep links (Phase 8) can reuse the same format.
    public nonisolated var storageKey: String {
        switch self {
        case .openLibraryWork(let id): "openlibrary:work:\(id)"
        case .tmdbFilm(let id): "tmdb:film:\(id)"
        case .tmdbShow(let id): "tmdb:show:\(id)"
        }
    }

    public nonisolated init?(storageKey: String) {
        let parts = storageKey.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3, !parts[2].isEmpty else { return nil }
        switch (parts[0], parts[1]) {
        case ("openlibrary", "work"): self = .openLibraryWork(parts[2])
        case ("tmdb", "film"):
            guard let id = Int(parts[2]) else { return nil }
            self = .tmdbFilm(id)
        case ("tmdb", "show"):
            guard let id = Int(parts[2]) else { return nil }
            self = .tmdbShow(id)
        default: return nil
        }
    }
}
