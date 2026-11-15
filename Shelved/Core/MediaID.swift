import Foundation

/// Identifies a book, film, or show across sources.
///
/// An enum (not a bare String) so the source is part of the identity:
/// an Open Library work and a TMDB film can never be confused.
///
/// TMDB films and shows get a case each, rather than the planned
/// `.tmdb(MediaKind, Int)`: that shape would allow `.tmdb(.book, 5)`, which
/// means nothing. TMDB numbers films and shows separately too, so film 550
/// and show 550 are different things.
///
/// `nonisolated`: these are plain values used from any thread (networking,
/// mapping, UI). See "Concurrency" in CLAUDE.md.
nonisolated enum MediaID: Hashable, Sendable {
    /// An Open Library work ID, e.g. "OL893414W".
    case openLibraryWork(String)
    /// A TMDB movie ID, e.g. 329865 (Arrival).
    case tmdbFilm(Int)
    /// A TMDB TV series ID, e.g. 95396 (Severance).
    case tmdbShow(Int)

    /// Known from the ID alone, so a screen can word things right
    /// ("Couldn't load this film") before anything has loaded.
    var kind: MediaKind {
        switch self {
        case .openLibraryWork: .book
        case .tmdbFilm: .film
        case .tmdbShow: .show
        }
    }
}
