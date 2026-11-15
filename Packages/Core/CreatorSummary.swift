import Foundation

/// Just enough about a creator to show their name and link to them.
public nonisolated struct CreatorSummary: Identifiable, Hashable, Sendable {
    public let id: CreatorID
    public let name: String

    public init(id: CreatorID, name: String) {
        self.id = id
        self.name = name
    }
}
