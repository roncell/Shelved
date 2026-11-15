import Foundation

/// `SeriesCatalog` backed by Wikidata.
///
/// An actor because it caches: series rarely change, and the same book's
/// series is asked for by Search, Detail and the Series screen. The cache
/// lives as long as the app does (memory only). `nil` memberships are cached
/// too, so a book with no series doesn't cost a request every time.
actor WikidataSeriesCatalog: SeriesCatalog {
    private let client: any HTTPClient
    private var seriesCache: [SeriesID: Series] = [:]
    private var membershipCache: [MediaID: SeriesMembership?] = [:]

    init(client: any HTTPClient = URLSessionHTTPClient(headers: [
        "User-Agent": WikidataAPI.userAgent,
        "Accept": "application/sparql-results+json",
    ])) {
        self.client = client
    }

    func membership(of item: MediaItem) async throws -> SeriesMembership? {
        if let cached = membershipCache[item.id] { return cached }
        guard case .openLibraryWork(let workID) = item.id, WikidataAPI.isOpenLibraryID(workID) else { return nil }

        let authorIDs = item.creators.compactMap { creator -> String? in
            if case .openLibraryAuthor(let id) = creator.id { id } else { nil }
        }
        let response = try await client.send(
            WikidataAPI.memberships(workID: workID, authorIDs: authorIDs, title: item.title)
        )
        let candidates = WikidataMapper.candidates(from: response)

        // A book can sit in several series (Dune is in "Dune" and "Dune
        // universe" lists). Load each and keep the one with the most books
        // we can open: that's the reading-order list people mean.
        var best: (candidate: WikidataMapper.Candidate, series: Series)?
        for candidate in candidates.prefix(3) {
            guard let series = try? await series(candidate.seriesID, fallbackName: candidate.name) else { continue }
            if best.map({ series.linkedWorkIDs.count > $0.series.linkedWorkIDs.count }) ?? true {
                best = (candidate, series)
            }
        }

        let membership = best.map {
            SeriesMembership(
                seriesID: $0.series.id, seriesName: $0.series.name, position: $0.candidate.position,
                total: $0.series.total, entryCount: $0.series.entries.count
            )
        }
        membershipCache[item.id] = .some(membership)
        return membership
    }

    func series(_ id: SeriesID) async throws -> Series {
        try await series(id, fallbackName: String(localized: "Series"))
    }

    private func series(_ id: SeriesID, fallbackName: String) async throws -> Series {
        if let cached = seriesCache[id] { return cached }
        switch id {
        case .wikidata(let qid):
            guard WikidataAPI.isQID(qid) else { throw NetworkError.invalidURL }
            let response = try await client.send(WikidataAPI.series(qid: qid))
            let series = WikidataMapper.series(from: response, id: id, fallbackName: fallbackName)
            seriesCache[id] = series
            return series
        }
    }
}
