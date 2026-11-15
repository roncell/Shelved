import Foundation

/// A series and its books in reading order.
nonisolated struct Series: Hashable, Sendable {
    let id: SeriesID
    let name: String
    /// Sorted by position, one entry per position.
    let entries: [SeriesEntry]

    /// True when the whole-number positions run 1, 2, 3… with no gaps.
    /// Screens only say "Book 2 of 5" when this holds: a gap means the
    /// source is missing a book, and a wrong total is worse than none.
    var isNumberingComplete: Bool {
        let wholes = entries.map(\.sortKey).filter { $0 >= 1 && $0.rounded() == $0 }
        return !wholes.isEmpty && wholes == (1...wholes.count).map(Double.init)
    }

    /// "of 5", only when the numbering can be trusted.
    var total: Int? {
        guard isNumberingComplete else { return nil }
        return entries.filter { $0.sortKey >= 1 && $0.sortKey.rounded() == $0.sortKey }.count
    }

    /// Entries that can be opened and saved.
    var linkedWorkIDs: [MediaID] { entries.compactMap(\.workID) }
}
