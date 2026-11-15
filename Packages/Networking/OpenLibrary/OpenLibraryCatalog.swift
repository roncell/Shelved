import Core
import Data
import Foundation

/// `MediaCatalog` backed by the Open Library API.
public nonisolated struct OpenLibraryCatalog: MediaCatalog {
    static let pageSize = 20
    /// Some works list dozens of contributors; we only show the first few.
    private static let maxAuthors = 5
    /// Merges can chain (A → B → C), but never far. A cap stops a bad loop.
    private static let maxRedirects = 3

    private let client: any HTTPClient

    /// The real thing, over the network.
    public init() {
        self.init(client: URLSessionHTTPClient(headers: ["User-Agent": OpenLibraryAPI.userAgent]))
    }

    /// Tests pass a fake client. Internal: `HTTPClient` isn't part of the
    /// module's public API, so the app can't (and needn't) choose one.
    init(client: any HTTPClient) {
        self.client = client
    }

    public func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage {
        guard kind == nil || kind == .book else { return SearchPage(items: [], hasMore: false) }
        let response = try await client.send(
            OpenLibraryAPI.search(query: query, page: page, limit: Self.pageSize)
        )
        return Self.page(from: response)
    }

    public func detail(for id: MediaID) async throws -> MediaDetail {
        switch id {
        case .openLibraryWork(let workID):
            let (canonicalID, work) = try await fetchFollowingRedirects(id: workID, endpoint: OpenLibraryAPI.work(id:))
            let creators = await authors(for: work)
            // Use the ID the record actually lives at, so anything saved from
            // this screen (Phase 4: a library entry) stores the canonical one.
            return OpenLibraryMapper.detail(from: work, id: .openLibraryWork(canonicalID), creators: creators)
        case .tmdbFilm, .tmdbShow:
            throw CatalogError.unsupportedID
        }
    }

    public func creator(for id: CreatorID) async throws -> CreatorDetail {
        switch id {
        case .openLibraryAuthor(let authorID):
            let (canonicalID, author) = try await fetchFollowingRedirects(id: authorID, endpoint: OpenLibraryAPI.author(id:))
            return OpenLibraryMapper.creatorDetail(from: author, authorID: canonicalID)
        case .tmdbPerson:
            throw CatalogError.unsupportedID
        }
    }

    public func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        switch id {
        case .openLibraryAuthor(let authorID):
            let response = try await client.send(
                OpenLibraryAPI.works(byAuthor: authorID, page: page, limit: Self.pageSize)
            )
            return Self.page(from: response)
        case .tmdbPerson:
            throw CatalogError.unsupportedID
        }
    }

    public func items(for ids: [MediaID]) async throws -> [MediaID: MediaItem] {
        let workIDs = ids.compactMap { id -> String? in
            if case .openLibraryWork(let workID) = id { workID } else { nil }
        }
        guard !workIDs.isEmpty else { return [:] }

        let response = try await client.send(OpenLibraryAPI.works(ids: workIDs))
        var found: [MediaID: MediaItem] = [:]
        for item in response.docs.compactMap(OpenLibraryMapper.item(from:)) {
            found[item.id] = item
        }

        // Merged records aren't in the search index under their old ID.
        // Fetch those one by one: `detail` follows the redirect, and the
        // result is keyed by the old ID but carries the canonical one.
        let missing = workIDs.map(MediaID.openLibraryWork).filter { found[$0] == nil }
        await withTaskGroup(of: (MediaID, MediaItem?).self) { group in
            for id in missing {
                group.addTask { (id, try? await detail(for: id).item) }
            }
            for await (id, item) in group {
                if let item { found[id] = item }
            }
        }
        return found
    }

    private static func page(from response: OLSearchResponse) -> SearchPage {
        let items = response.docs.compactMap(OpenLibraryMapper.item(from:))
        let hasMore = response.start + response.docs.count < response.numFound
        return SearchPage(items: items, hasMore: hasMore)
    }

    /// Fetches a work or author, following merge redirects to the real record.
    ///
    /// Generic over the record type, so works and authors share one loop.
    /// `endpoint` is a function value: callers pass `OpenLibraryAPI.work(id:)`
    /// itself, not a closure that calls it.
    private func fetchFollowingRedirects<Record: Decodable & Sendable & OLRedirectable>(
        id: String,
        endpoint: (String) -> Endpoint<Record>
    ) async throws -> (id: String, record: Record) {
        var currentID = id
        for _ in 0...Self.maxRedirects {
            let record = try await client.send(endpoint(currentID))
            guard let redirectKey = record.redirectKey else {
                return (currentID, record)
            }
            guard let nextID = OpenLibraryMapper.id(fromKey: redirectKey) else {
                throw NetworkError.invalidResponse
            }
            currentID = nextID
        }
        throw NetworkError.tooManyRedirects
    }

    /// A work only has author *keys*, so each name needs its own request.
    ///
    /// A task group runs those requests **in parallel** (structured concurrency):
    /// 3 authors take about as long as 1. If the detail screen is closed, the
    /// parent task is cancelled and every child request is cancelled with it.
    private func authors(for work: OLWork) async -> [CreatorSummary] {
        let authorIDs = (work.authors ?? [])
            .compactMap { $0.author?.key }
            .compactMap(OpenLibraryMapper.id(fromKey:))
            .prefix(Self.maxAuthors)

        return await withTaskGroup(of: (Int, CreatorSummary?).self) { group in
            for (index, authorID) in authorIDs.enumerated() {
                group.addTask {
                    // `try?`: one failed author lookup shouldn't fail the whole screen.
                    let fetched = try? await fetchFollowingRedirects(id: authorID, endpoint: OpenLibraryAPI.author(id:))
                    let creator = fetched.flatMap { OpenLibraryMapper.creator(from: $0.record, authorID: $0.id) }
                    return (index, creator)
                }
            }

            // Children finish in any order; collect them, then restore the original order.
            var results: [(index: Int, creator: CreatorSummary)] = []
            for await (index, creator) in group {
                if let creator { results.append((index, creator)) }
            }
            return results.sorted { $0.index < $1.index }.map(\.creator)
        }
    }
}
