import Foundation

/// A shelf as screens see it: a plain value, not the SwiftData object.
public nonisolated struct ShelfSummary: Identifiable, Hashable, Sendable {
    public let id: ShelfID
    public let name: String
    /// Which built-in shelf this is, or nil for a shelf the user created.
    public let system: SystemShelf?
    public let itemCount: Int

    public init(id: ShelfID, name: String, system: SystemShelf?, itemCount: Int) {
        self.id = id
        self.name = name
        self.system = system
        self.itemCount = itemCount
    }

    public var isSystem: Bool { system != nil }
    public var systemImage: String { system?.systemImage ?? "folder" }
}
