import Core
import Data
import Foundation

/// The standard SPARQL JSON result: one dictionary per row, keyed by the
/// query's variable names. Variables in an OPTIONAL that didn't match are
/// simply missing from the row.
nonisolated struct WikidataResponse: Decodable, Sendable {
    let results: Results

    nonisolated struct Results: Decodable, Sendable {
        let bindings: [[String: Term]]
    }

    /// One value: a URI ("http://www.wikidata.org/entity/Q45875") or a literal ("1").
    nonisolated struct Term: Decodable, Sendable {
        let value: String
    }

    var rows: [[String: String]] {
        results.bindings.map { $0.mapValues(\.value) }
    }
}
