import Core
import Data
import Foundation

/// Turns Wikidata rows into series. This is where the data gets cleaned up,
/// because Wikidata is crowd-edited and messy in predictable ways (found in
/// the Phase 5.5 spike):
/// - a book can have several Open Library IDs → one row each
/// - translations share the original's position ("Kampen om jerntronen" is also #2)
/// - some members have no English label, only their Q-ID
nonisolated enum WikidataMapper {
    nonisolated struct Candidate: Hashable, Sendable {
        let seriesID: SeriesID
        let name: String
        let position: String
    }

    static func candidates(from response: WikidataResponse) -> [Candidate] {
        var seen = Set<SeriesID>()
        return response.rows.compactMap { row -> Candidate? in
            guard let qid = row["series"].flatMap(qid(fromURI:)),
                  let position = row["ord"].flatMap(cleanPosition),
                  let name = row["seriesLabel"], !isBareQID(name)
            else { return nil }
            let id = SeriesID.wikidata(qid)
            guard seen.insert(id).inserted else { return nil }
            return Candidate(seriesID: id, name: name, position: position)
        }
    }

    static func series(from response: WikidataResponse, id: SeriesID, fallbackName: String) -> Series {
        let rows = response.rows

        // Group rows by book, keeping the first work ID seen.
        var books: [String: (title: String, position: String, sortKey: Double, workID: String?)] = [:]
        for row in rows {
            guard let book = row["book"],
                  let position = row["ord"].flatMap(cleanPosition),
                  let sortKey = Double(position),
                  let title = row["bookLabel"]
            else { continue }
            let workID = row["ol"].flatMap { WikidataAPI.isOpenLibraryID($0) ? $0 : nil }
            if var existing = books[book] {
                existing.workID = existing.workID ?? workID
                books[book] = existing
            } else {
                books[book] = (title, position, sortKey, workID)
            }
        }

        // One book per position. Prefer one we can open, then one with a
        // real title, then the lowest Q-number (usually the original work).
        let byPosition = Dictionary(grouping: books, by: \.value.position)
        let entries = byPosition.values.compactMap { group -> SeriesEntry? in
            let best = group.min { lhs, rhs in
                rank(lhs.value.workID, lhs.value.title, lhs.key) < rank(rhs.value.workID, rhs.value.title, rhs.key)
            }
            guard let best else { return nil }
            return SeriesEntry(
                position: best.value.position,
                sortKey: best.value.sortKey,
                title: best.value.title,
                workID: best.value.workID.map(MediaID.openLibraryWork)
            )
        }

        let name = rows.lazy.compactMap { $0["seriesName"] }.first ?? fallbackName
        return Series(id: id, name: name, entries: entries.sorted { $0.sortKey < $1.sortKey })
    }

    /// "http://www.wikidata.org/entity/Q45875" → "Q45875"
    static func qid(fromURI uri: String) -> String? {
        guard let last = uri.split(separator: "/").last.map(String.init), WikidataAPI.isQID(last) else { return nil }
        return last
    }

    /// Positions must be numbers ("1", "0.5"). Text like "prequel" can't be ordered.
    private static func cleanPosition(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard let value = Double(trimmed), value >= 0 else { return nil }
        return trimmed
    }

    private static func isBareQID(_ label: String) -> Bool {
        WikidataAPI.isQID(label)
    }

    private static func rank(_ workID: String?, _ title: String, _ bookURI: String) -> (Int, Int, Int) {
        let qNumber = qid(fromURI: bookURI).flatMap { Int($0.dropFirst()) } ?? .max
        return (workID == nil ? 1 : 0, isBareQID(title) ? 1 : 0, qNumber)
    }
}
