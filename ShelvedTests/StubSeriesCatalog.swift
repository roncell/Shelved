import Foundation
@testable import Shelved

/// Canned series answers. By default: "not in a series".
nonisolated struct StubSeriesCatalog: SeriesCatalog {
    var membershipResult: SeriesMembership?
    var seriesResult: Series?
    /// Thrown by every call when set.
    var error: (any Error)?

    func membership(of item: MediaItem) async throws -> SeriesMembership? {
        if let error { throw error }
        return membershipResult
    }

    func series(_ id: SeriesID) async throws -> Series {
        if let error { throw error }
        guard let seriesResult else { throw URLError(.fileDoesNotExist) }
        return seriesResult
    }
}
