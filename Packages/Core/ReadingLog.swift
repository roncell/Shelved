import Foundation

/// The user's own notes on an item: everything the review screen edits.
///
/// A value type, so the editor works on a *copy*. Nothing is saved until
/// the user taps Save, and backing out discards changes for free.
public nonisolated struct ReadingLog: Hashable, Sendable {
    public var rating: Rating?
    /// Empty means "no review". A non-optional String binds straight to a TextEditor.
    public var review: String = ""
    /// Pages for books (episodes for shows, in Phase 6).
    public var progress: Int?
    public var progressTotal: Int?
    public var startedAt: Date?
    public var finishedAt: Date?

    public init(
        rating: Rating? = nil, review: String = "", progress: Int? = nil, progressTotal: Int? = nil,
        startedAt: Date? = nil, finishedAt: Date? = nil
    ) {
        self.rating = rating
        self.review = review
        self.progress = progress
        self.progressTotal = progressTotal
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }

    public var isEmpty: Bool {
        self == ReadingLog()
    }

    /// Fills in dates the user would otherwise have to enter by hand:
    /// starting a book sets "started", finishing it sets "finished".
    /// Dates the user already set are never overwritten.
    public func movedTo(_ shelf: SystemShelf?, at date: Date) -> ReadingLog {
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
    public var validationErrors: [String] {
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
