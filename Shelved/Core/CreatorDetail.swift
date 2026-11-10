import Foundation

/// Everything the creator screen shows about a person.
///
/// Same split as `MediaItem` / `MediaDetail`: `CreatorSummary` is the
/// name-and-ID you get inside other records; this is the full profile you
/// only get by asking for the creator directly.
nonisolated struct CreatorDetail: Hashable, Sendable {
    let id: CreatorID
    let name: String
    let bio: String?
    /// Free text as the source gives it ("8 October 1920"). Open Library
    /// dates aren't reliably parseable, so they stay strings for display.
    let birthDate: String?
    let deathDate: String?
    let photoURL: URL?
}
