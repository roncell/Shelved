import Foundation
@testable import Shelved

/// A *spy*: answers like `StubCatalog`, and also records every call, so a
/// test can check *how* a ViewModel used the catalog (how many requests,
/// which pages), not only what ended up on screen.
///
/// The test doubles in this target, from simplest to most involved:
/// - **Stub** (`StubCatalog`, `FailingLibraryRepository`): canned answers or errors.
/// - **Spy** (this): a stub that also records calls for the test to inspect afterwards.
/// - **Mock**: a spy that knows its expected calls up front and fails the
///   test itself. Not used here; asserting on a spy's record in the test
///   keeps each expectation visible where it matters.
/// - **Fake**: a real, lighter implementation. `SwiftDataLibraryRepository.inMemory()`
///   is the real repository on a throwaway store; `PreviewCatalog` is a fake catalog.
///
/// An actor, because the catalog is `Sendable` and called from async code:
/// the actor keeps the call log safe without locks.
actor SpyCatalog: MediaCatalog {
    struct SearchCall: Equatable {
        let query: String
        var kind: MediaKind? = nil
        let page: Int
    }

    private let stub: StubCatalog
    private(set) var searches: [SearchCall] = []
    private(set) var detailRequests: [MediaID] = []

    init(_ stub: StubCatalog) {
        self.stub = stub
    }

    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage {
        searches.append(SearchCall(query: query, kind: kind, page: page))
        return try await stub.search(query: query, kind: kind, page: page)
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        detailRequests.append(id)
        return try await stub.detail(for: id)
    }

    func creator(for id: CreatorID) async throws -> CreatorDetail {
        try await stub.creator(for: id)
    }

    func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        try await stub.works(by: id, page: page)
    }

    func items(for ids: [MediaID]) async throws -> [MediaID: MediaItem] {
        try await stub.items(for: ids)
    }
}
