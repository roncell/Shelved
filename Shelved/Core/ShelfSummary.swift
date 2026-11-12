import Foundation

/// A shelf as screens see it: a plain value, not the SwiftData object.
nonisolated struct ShelfSummary: Identifiable, Hashable, Sendable {
    let id: ShelfID
    let name: String
    /// Which built-in shelf this is, or nil for a shelf the user created.
    let system: SystemShelf?
    let itemCount: Int

    var isSystem: Bool { system != nil }
    var systemImage: String { system?.systemImage ?? "folder" }
}
