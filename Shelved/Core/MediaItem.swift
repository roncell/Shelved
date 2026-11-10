import Foundation

/// A lightweight item, as shown in search results and lists.
///
/// This is *our* model, not Open Library's JSON. The mapper converts API
/// responses into it, so if the API changes shape only the mapper changes.
nonisolated struct MediaItem: Identifiable, Hashable, Sendable {
    let id: MediaID
    let kind: MediaKind
    let title: String
    let creators: [CreatorSummary]
    let coverURL: URL?
    let year: Int?
}
