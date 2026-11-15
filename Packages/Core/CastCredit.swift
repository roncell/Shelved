import Foundation

/// One actor in a film or show's cast, and who they played.
public nonisolated struct CastCredit: Identifiable, Hashable, Sendable {
    public let person: CreatorSummary
    /// Empty roles come through as nil, not "".
    public let character: String?

    public init(person: CreatorSummary, character: String?) {
        self.person = person
        self.character = character
    }

    public var id: CreatorID { person.id }
}
