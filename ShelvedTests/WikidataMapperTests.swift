import Foundation
import Testing
@testable import Core
@testable import Data
@testable import Networking

/// Builds a SPARQL JSON response from rows of plain strings.
func sparqlJSON(_ rows: [[String: String]]) -> String {
    let bindings = rows.map { row in
        "{" + row.map { #""\#($0.key)": {"type": "literal", "value": "\#($0.value)"}"# }.joined(separator: ",") + "}"
    }
    return #"{"head": {"vars": []}, "results": {"bindings": [\#(bindings.joined(separator: ","))]}}"#
}

private func decode(_ json: String) throws -> WikidataResponse {
    try JSONDecoder().decode(WikidataResponse.self, from: Data(json.utf8))
}

private let entity = "http://www.wikidata.org/entity/"

struct WikidataMapperTests {
    /// The real shape of A Song of Ice and Fire, trimmed (from the spike).
    @Test func seriesKeepsOneBookPerPositionInOrder() throws {
        let response = try decode(sparqlJSON([
            ["book": entity + "Q2", "bookLabel": "A Clash of Kings", "ord": "2", "ol": "OL257939W", "seriesName": "A Song of Ice and Fire"],
            ["book": entity + "Q2", "bookLabel": "A Clash of Kings", "ord": "2", "ol": "OL1955946W"],
            ["book": entity + "Q9", "bookLabel": "Kampen om jerntronen", "ord": "2"],   // translation, same position
            ["book": entity + "Q1", "bookLabel": "A Game of Thrones", "ord": "1", "ol": "OL257943W"],
            ["book": entity + "Q7", "bookLabel": "A Dream of Spring", "ord": "7"],      // unpublished, no OL ID
            ["book": entity + "Q8", "bookLabel": "Q8", "ord": "8"],                      // no English label
            ["book": entity + "Q5", "bookLabel": "Spin-off", "ord": "novella"],         // can't be ordered
        ]))

        let series = WikidataMapper.series(from: response, id: .wikidata("Q45875"), fallbackName: "Series")

        #expect(series.name == "A Song of Ice and Fire")
        #expect(series.entries.map(\.title) == ["A Game of Thrones", "A Clash of Kings", "A Dream of Spring", "Q8"])
        #expect(series.entries[1].workID == .openLibraryWork("OL257939W"))   // first ID seen, not a duplicate row
        #expect(series.entries[2].workID == nil)
        #expect(series.linkedWorkIDs.count == 2)
    }

    @Test func gapsMeanNoTotal() {
        func series(_ positions: [Double]) -> Series {
            Series(id: .wikidata("Q1"), name: "S", entries: positions.map {
                SeriesEntry(position: String($0), sortKey: $0, title: "B", workID: nil)
            })
        }
        #expect(series([1, 2, 3]).total == 3)
        #expect(series([0.5, 1, 2]).total == 2)        // a prequel novella doesn't break the count
        #expect(series([1, 2, 4]).total == nil)        // book 3 missing
        #expect(series([2, 3]).total == nil)           // book 1 missing
        #expect(series([]).total == nil)
    }

    @Test func candidatesDropUnlabelledAndDuplicateSeries() throws {
        let response = try decode(sparqlJSON([
            ["series": entity + "Q6095696", "seriesLabel": "Dune", "ord": "1"],
            ["series": entity + "Q6095696", "seriesLabel": "Dune", "ord": "1"],
            ["series": entity + "Q1234", "seriesLabel": "Q1234", "ord": "1"],
        ]))

        let candidates = WikidataMapper.candidates(from: response)

        #expect(candidates == [WikidataMapper.Candidate(seriesID: .wikidata("Q6095696"), name: "Dune", position: "1")])
    }
}

struct WikidataAPITests {
    @Test func titlesAreEscapedAndBadIDsLeftOut() throws {
        let endpoint = WikidataAPI.memberships(
            workID: "OL1W", authorIDs: ["OL79034A", "OL1A\" } DROP"], title: #"The "Best" Book"#
        )
        let query = try #require(endpoint.queryItems.first { $0.name == "query" }?.value)

        #expect(query.contains(#""the \"best\" book""#))
        #expect(query.contains(#""OL79034A""#))
        #expect(!query.contains("DROP"))
    }

    @Test func idValidation() {
        #expect(WikidataAPI.isOpenLibraryID("OL893414W"))
        #expect(WikidataAPI.isOpenLibraryID("OL79034A"))
        #expect(!WikidataAPI.isOpenLibraryID("OL893414M"))   // an edition, not a work
        #expect(!WikidataAPI.isOpenLibraryID("OL1W\""))
        #expect(WikidataAPI.isQID("Q45875"))
        #expect(!WikidataAPI.isQID("Q45875 }"))
    }
}
