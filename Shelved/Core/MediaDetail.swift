import Foundation

/// Everything the detail screen shows.
///
/// Separate from `MediaItem` because search results don't include a summary
/// or subjects. Two honest types beat one type full of fields that are
/// "sometimes nil depending on where it came from".
///
/// The subject lists are empty (not nil) when missing: the view only cares
/// whether there's something to show, and `[]` says that without unwrapping.
nonisolated struct MediaDetail: Hashable, Sendable {
    let id: MediaID
    let kind: MediaKind
    let title: String
    let creators: [CreatorSummary]
    let coverURL: URL?
    let year: Int?
    let summary: String?
    let subjects: [String]
    let places: [String]
    let characters: [String]
    let timePeriods: [String]
    let links: [MediaLink]
}
