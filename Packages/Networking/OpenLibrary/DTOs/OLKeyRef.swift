import Core
import Data
import Foundation

/// `{ "key": "/authors/OL79034A" }`
nonisolated struct OLKeyRef: Decodable, Sendable {
    let key: String
}
