import Foundation

/// An entry in a work's `authors` array:
/// `{ "author": { "key": "/authors/OL79034A" }, "type": {...} }`
/// Note: only the key, no name. Names need a separate /authors call.
nonisolated struct OLWorkAuthor: Decodable, Sendable {
    let author: OLKeyRef?
}
