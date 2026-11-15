import Foundation

/// A lightweight item, as shown in search results and lists.
///
/// This is *our* model, not Open Library's JSON. The mapper converts API
/// responses into it, so if the API changes shape only the mapper changes.
public nonisolated struct MediaItem: Identifiable, Hashable, Sendable {
    public let id: MediaID
    public let kind: MediaKind
    public let title: String
    public let creators: [CreatorSummary]
    public let coverURL: URL?
    public let year: Int?

    public init(id: MediaID, kind: MediaKind, title: String, creators: [CreatorSummary], coverURL: URL?, year: Int?) {
        self.id = id
        self.kind = kind
        self.title = title
        self.creators = creators
        self.coverURL = coverURL
        self.year = year
    }
}
