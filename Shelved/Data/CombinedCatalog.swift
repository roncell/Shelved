import Foundation

/// One `MediaCatalog` over every source: Open Library for books, TMDB for
/// films and shows. Screens don't know there's more than one.
///
/// **Routing:** an ID says which source it came from, so `detail`,
/// `creator` and `works` pick the source with an exhaustive `switch`.
/// Add a third source and the compiler points here.
///
/// **Search** asks every source that carries the requested kind, in
/// parallel, and interleaves the results (A1, B1, A2, B2…). Relevance
/// scores from two different APIs can't be compared, so taking turns is
/// the fairest order available.
nonisolated struct CombinedCatalog: MediaCatalog {
    let openLibrary: any MediaCatalog
    let tmdb: any MediaCatalog

    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage {
        let sources = sources(for: kind)

        // Each child returns its index so results can be put back in source order.
        let results = await withTaskGroup(of: (Int, Result<SearchPage, any Error>).self) { group in
            for (index, source) in sources.enumerated() {
                group.addTask {
                    do {
                        return (index, .success(try await source.search(query: query, kind: kind, page: page)))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            var collected: [(Int, Result<SearchPage, any Error>)] = []
            for await result in group { collected.append(result) }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }

        // One source failing (offline TMDB, no token) shouldn't hide the
        // other's results. Only when *every* source failed is it an error.
        let pages = results.compactMap { try? $0.get() }
        if pages.isEmpty, let firstFailure = results.first, case .failure(let error) = firstFailure {
            throw error
        }
        return SearchPage(
            items: Self.interleave(pages.map(\.items)),
            hasMore: pages.contains(where: \.hasMore)
        )
    }

    func detail(for id: MediaID) async throws -> MediaDetail {
        try await source(for: id).detail(for: id)
    }

    func creator(for id: CreatorID) async throws -> CreatorDetail {
        try await source(for: id).creator(for: id)
    }

    func works(by id: CreatorID, page: Int) async throws -> SearchPage {
        try await source(for: id).works(by: id, page: page)
    }

    func items(for ids: [MediaID]) async throws -> [MediaID: MediaItem] {
        // Split by source, ask both in parallel, merge.
        var openLibraryIDs: [MediaID] = []
        var tmdbIDs: [MediaID] = []
        for id in ids {
            switch id {
            case .openLibraryWork: openLibraryIDs.append(id)
            case .tmdbFilm, .tmdbShow: tmdbIDs.append(id)
            }
        }
        async let fromOpenLibrary = Self.items(for: openLibraryIDs, in: openLibrary)
        async let fromTMDB = Self.items(for: tmdbIDs, in: tmdb)
        return try await fromOpenLibrary.merging(fromTMDB) { first, _ in first }
    }

    private static func items(for ids: [MediaID], in source: any MediaCatalog) async throws -> [MediaID: MediaItem] {
        ids.isEmpty ? [:] : try await source.items(for: ids)
    }

    // MARK: - Routing

    private func sources(for kind: MediaKind?) -> [any MediaCatalog] {
        switch kind {
        case nil: [openLibrary, tmdb]
        case .book: [openLibrary]
        case .film, .show: [tmdb]
        }
    }

    private func source(for id: MediaID) -> any MediaCatalog {
        switch id {
        case .openLibraryWork: openLibrary
        case .tmdbFilm, .tmdbShow: tmdb
        }
    }

    private func source(for id: CreatorID) -> any MediaCatalog {
        switch id {
        case .openLibraryAuthor: openLibrary
        case .tmdbPerson: tmdb
        }
    }

    /// [[A1, A2, A3], [B1]] → [A1, B1, A2, A3]
    static func interleave(_ lists: [[MediaItem]]) -> [MediaItem] {
        var merged: [MediaItem] = []
        let longest = lists.map(\.count).max() ?? 0
        for position in 0..<longest {
            for list in lists where position < list.count {
                merged.append(list[position])
            }
        }
        return merged
    }
}
