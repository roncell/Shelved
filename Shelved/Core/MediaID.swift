import Foundation

/// Identifies a book, film, or show across sources.
///
/// Phase 1: a plain string wrapper so routes have something to carry.
/// Phase 2/6 will turn this into `.openLibrary(String)` / `.tmdb(kind, Int)`.
/// Because routes only ever carry IDs, that change won't touch navigation code.
struct MediaID: Hashable, Sendable {
    let rawValue: String
}
