import Foundation

nonisolated enum LibraryError: Error, Equatable {
    case shelfNotFound
    case itemNotFound
    case emptyShelfName
    case duplicateShelfName
    case cannotDeleteSystemShelf

    var message: String {
        switch self {
        case .shelfNotFound: String(localized: "That shelf no longer exists.")
        case .itemNotFound: String(localized: "That item is no longer in your library.")
        case .emptyShelfName: String(localized: "Give the shelf a name.")
        case .duplicateShelfName: String(localized: "You already have a shelf with that name.")
        case .cannotDeleteSystemShelf: String(localized: "Built-in shelves can't be deleted.")
        }
    }
}
