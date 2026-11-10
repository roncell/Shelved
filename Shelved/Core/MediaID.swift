import Foundation

/// Identifies a book, film, or show across sources.
///
/// An enum (not a bare String) so the source is part of the identity:
/// an Open Library work and a TMDB film can never be confused.
/// Phase 6 adds `case tmdb(MediaKind, Int)`, and the compiler will point
/// at every `switch` that needs to handle it.
///
/// `nonisolated`: these are plain values used from any thread (networking,
/// mapping, UI). See "Concurrency" in CLAUDE.md.
nonisolated enum MediaID: Hashable, Sendable {
    /// An Open Library work ID, e.g. "OL893415W".
    case openLibraryWork(String)
}
