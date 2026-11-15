import Foundation

extension CreatorID {
    /// A stable string form for storage: "openlibrary:author:OL79034A".
    /// Same scheme as `MediaID.storageKey`.
    public nonisolated var storageKey: String {
        switch self {
        case .openLibraryAuthor(let id): "openlibrary:author:\(id)"
        case .tmdbPerson(let id): "tmdb:person:\(id)"
        }
    }

    public nonisolated init?(storageKey: String) {
        let parts = storageKey.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3, !parts[2].isEmpty else { return nil }
        switch (parts[0], parts[1]) {
        case ("openlibrary", "author"): self = .openLibraryAuthor(parts[2])
        case ("tmdb", "person"):
            guard let id = Int(parts[2]) else { return nil }
            self = .tmdbPerson(id)
        default: return nil
        }
    }
}
