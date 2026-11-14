import Foundation

/// The user's own notes on an item: everything the review screen edits.
///
/// A value type, so the editor works on a *copy*. Nothing is saved until
/// the user taps Save, and backing out discards changes for free.
nonisolated struct ReadingLog: Hashable, Sendable {
    var rating: Rating?
    /// Empty means "no review". A non-optional String binds straight to a TextEditor.
    var review = ""
    /// Pages for books (episodes for shows, in Phase 6).
    var progress: Int?
    var progressTotal: Int?
    var startedAt: Date?
    var finishedAt: Date?

    var isEmpty: Bool {
        self == ReadingLog()
    }

    /// Fills in dates the user would otherwise have to enter by hand:
    /// starting a book sets "started", finishing it sets "finished".
    /// Dates the user already set are never overwritten.
    func movedTo(_ shelf: SystemShelf?, at date: Date) -> ReadingLog {
        var log = self
        switch shelf {
        case .inProgress:
            log.startedAt = startedAt ?? date
        case .finished:
            log.finishedAt = finishedAt ?? date
        case .wantTo, nil:
            break
        }
        return log
    }

    /// Problems that should block saving, in display order.
    var validationErrors: [String] {
        var errors: [String] = []
        if let progress, let progressTotal, progress > progressTotal {
            errors.append(String(localized: "Current page is past the last page."))
        }
        if let startedAt, let finishedAt, finishedAt < startedAt {
            errors.append(String(localized: "Finish date is before the start date."))
        }
        return errors
    }
}
