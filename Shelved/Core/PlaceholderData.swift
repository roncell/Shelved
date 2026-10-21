import Foundation

/// Fake data so Phase 1 screens have something to tap.
/// Deleted once real search arrives in Phase 2.
enum PlaceholderData {
    struct Item: Identifiable, Hashable {
        let id: MediaID
        let title: String
        let creatorID: CreatorID
        let creatorName: String
    }

    static let items: [Item] = [
        Item(id: MediaID(rawValue: "dune"), title: "Dune",
             creatorID: CreatorID(rawValue: "herbert"), creatorName: "Frank Herbert"),
        Item(id: MediaID(rawValue: "children-of-dune"), title: "Children of Dune",
             creatorID: CreatorID(rawValue: "herbert"), creatorName: "Frank Herbert"),
        Item(id: MediaID(rawValue: "left-hand"), title: "The Left Hand of Darkness",
             creatorID: CreatorID(rawValue: "le-guin"), creatorName: "Ursula K. Le Guin"),
        Item(id: MediaID(rawValue: "dispossessed"), title: "The Dispossessed",
             creatorID: CreatorID(rawValue: "le-guin"), creatorName: "Ursula K. Le Guin"),
    ]

    static func item(_ id: MediaID) -> Item? {
        items.first { $0.id == id }
    }

    static func works(by creator: CreatorID) -> [Item] {
        items.filter { $0.creatorID == creator }
    }

    static func creatorName(_ id: CreatorID) -> String {
        items.first { $0.creatorID == id }?.creatorName ?? "Unknown"
    }
}
