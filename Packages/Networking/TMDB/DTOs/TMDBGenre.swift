import Core
import Data
import Foundation

nonisolated struct TMDBGenre: Decodable, Sendable {
    let id: Int
    let name: String
}
