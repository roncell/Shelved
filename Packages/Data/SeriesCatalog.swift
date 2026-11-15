import Core
import Foundation

/// Book series: which series a book is in, and every book in a series.
///
/// A separate protocol from `MediaCatalog` because it's a separate source
/// (Wikidata), joined to Open Library by work ID. Screens that don't care
/// about series don't depend on it.
public nonisolated protocol SeriesCatalog: Sendable {
    /// nil when the book isn't in a numbered series, or it's not a book.
    /// Takes the whole item because matching may fall back to title + author.
    func membership(of item: MediaItem) async throws -> SeriesMembership?
    func series(_ id: SeriesID) async throws -> Series
}
