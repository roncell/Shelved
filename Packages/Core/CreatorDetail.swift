import Foundation

/// Everything the creator screen shows about a person.
///
/// Same split as `MediaItem` / `MediaDetail`: `CreatorSummary` is the
/// name-and-ID you get inside other records; this is the full profile you
/// only get by asking for the creator directly.
public nonisolated struct CreatorDetail: Hashable, Sendable {
    public let id: CreatorID
    public let name: String
    public let bio: String?
    /// Free text as the source gives it ("8 October 1920"). Open Library
    /// dates aren't reliably parseable, so they stay strings for display.
    public let birthDate: String?
    public let deathDate: String?
    public let photoURL: URL?

    public init(id: CreatorID, name: String, bio: String?, birthDate: String?, deathDate: String?, photoURL: URL?) {
        self.id = id
        self.name = name
        self.bio = bio
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.photoURL = photoURL
    }
}
