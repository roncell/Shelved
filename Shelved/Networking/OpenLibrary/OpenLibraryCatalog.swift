import Foundation

/// `MediaCatalog` backed by the Open Library API.
nonisolated struct OpenLibraryCatalog: MediaCatalog {
    static let pageSize = 20
    /// Some works list dozens of contributors; we only show the first few.
    private static let maxAuthors = 5

    private let client: any HTTPClient

    init(client: any HTTPClient = URLSessionHTTPClient(headers: ["User-Agent": OpenLibraryAPI.userAgent])) {
        self.client = client
    }

    func search(query: String, page: Int) async throws -> SearchPage {
        let response = try await client.send(
            OpenLibraryAPI.search(query: query, page: page, limit: Self.pageSize)
        )
        let items = response.docs.compactMap(OpenLibraryMapper.item(from:))
        let hasMore = response.start + response.docs.count < response.numFound
        return SearchPage(items: items, hasMore: hasMore)
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        switch id {
        case .openLibraryWork(let workID):
            let work = try await client.send(OpenLibraryAPI.work(id: workID))
            let creators = await authors(for: work)
            return OpenLibraryMapper.detail(from: work, id: id, creators: creators)
        }
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
                    let author = try? await client.send(OpenLibraryAPI.author(id: authorID))
                    let creator = author.flatMap { OpenLibraryMapper.creator(from: $0, authorID: authorID) }
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
