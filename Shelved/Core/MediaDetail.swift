import Foundation

/// Everything the detail screen shows.
///
/// Separate from `MediaItem` because search results don't include a summary
/// or subjects. Two honest types beat one type full of fields that are
/// "sometimes nil depending on where it came from".
nonisolated struct MediaDetail: Hashable, Sendable {
    let id: MediaID
    let kind: MediaKind
    let title: String
    let creators: [CreatorSummary]
    let coverURL: URL?
    let year: Int?
    let summary: String?
    let subjects: [String]
}
