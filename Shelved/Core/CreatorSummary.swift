import Foundation

/// Just enough about a creator to show their name and link to them.
nonisolated struct CreatorSummary: Identifiable, Hashable, Sendable {
    let id: CreatorID
    let name: String
}
