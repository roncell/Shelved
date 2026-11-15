import Foundation

/// Everything the detail screen shows.
///
/// Separate from `MediaItem` because search results don't include a summary
/// or subjects. Two honest types beat one type full of fields that are
/// "sometimes nil depending on where it came from".
///
/// The subject lists are empty (not nil) when missing: the view only cares
/// whether there's something to show, and `[]` says that without unwrapping.
public nonisolated struct MediaDetail: Hashable, Sendable {
    public let id: MediaID
    public let kind: MediaKind
    public let title: String
    public let creators: [CreatorSummary]
    public let coverURL: URL?
    public let year: Int?
    public let summary: String?
    public let subjects: [String]
    public let places: [String]
    public let characters: [String]
    public let timePeriods: [String]
    public let links: [MediaLink]

    // Films and shows only. Defaulted so book code (and the saved-copy
    // fallback) doesn't have to spell out fields it never has.
    public var cast: [CastCredit] = []
    public var runtimeMinutes: Int?
    public var seasonCount: Int?
    public var episodeCount: Int?

    public init(
        id: MediaID, kind: MediaKind, title: String, creators: [CreatorSummary], coverURL: URL?, year: Int?,
        summary: String?, subjects: [String], places: [String], characters: [String], timePeriods: [String],
        links: [MediaLink], cast: [CastCredit] = [], runtimeMinutes: Int? = nil, seasonCount: Int? = nil,
        episodeCount: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.creators = creators
        self.coverURL = coverURL
        self.year = year
        self.summary = summary
        self.subjects = subjects
        self.places = places
        self.characters = characters
        self.timePeriods = timePeriods
        self.links = links
        self.cast = cast
        self.runtimeMinutes = runtimeMinutes
        self.seasonCount = seasonCount
        self.episodeCount = episodeCount
    }
}
