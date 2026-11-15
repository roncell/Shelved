import Core
import Data
import Foundation

/// A person named inside another record, e.g. a show's `created_by`.
nonisolated struct TMDBPersonRef: Decodable, Sendable {
    let id: Int
    let name: String
}
