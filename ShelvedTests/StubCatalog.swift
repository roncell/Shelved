import Foundation
@testable import Shelved

/// A fake catalog that returns pre-set data. This is why `MediaCatalog`
/// is a protocol: the ViewModel can't tell this apart from Open Library.
///
/// It's a *stub* (canned answers), not a *mock* (records calls to assert on).
/// Phase 5 is where that difference gets its own lesson.
nonisolated struct StubCatalog: MediaCatalog {
    var pages: [Int: SearchPage] = [:]
    var creator: CreatorDetail?
    var worksPages: [Int: SearchPage] = [:]
    /// Thrown by every call when set.
    var error: (any Error)?
    /// Thrown only by `works(by:page:)`, to test a partial failure.
    var worksError: (any Error)?

    func search(query: String, page: Int) async throws -> SearchPage {
        if let error { throw error }
        return pages[page] ?? SearchPage(items: [], hasMore: false)
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        throw URLError(.unsupportedURL)
    }

    func creator(for id: CreatorID) async throws -> CreatorDetail {
        if let error { throw error }
        guard let creator else { throw URLError(.fileDoesNotExist) }
        return creator
    }

    func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        if let error = error ?? worksError { throw error }
        return worksPages[page] ?? SearchPage(items: [], hasMore: false)
    }
}
