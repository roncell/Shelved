import Foundation

/// One actor in a film or show's cast, and who they played.
nonisolated struct CastCredit: Identifiable, Hashable, Sendable {
    let person: CreatorSummary
    /// Empty roles come through as nil, not "".
    let character: String?

    var id: CreatorID { person.id }
}
