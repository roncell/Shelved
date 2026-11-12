import Foundation

extension SwiftDataLibraryRepository {
    /// An in-memory library with a couple of saved books, for `#Preview`s.
    ///
    /// Previews use the *real* repository on a throwaway store rather than a
    /// hand-written fake: it's no extra code, and previews exercise the same
    /// mapping the app does.
    static func preview() -> SwiftDataLibraryRepository {
        do {
            let repository = try inMemory()
            let shelves = try repository.shelves()
            if let inProgress = shelves.first(where: { $0.system == .inProgress }),
               let wantTo = shelves.first(where: { $0.system == .wantTo }) {
                try repository.save(PreviewCatalog.items[0], to: inProgress.id)
                try repository.updateLog(
                    ReadingLog(rating: Rating(stars: 4.5), review: "Spice, sand, and politics.",
                               progress: 212, progressTotal: 617, startedAt: .now),
                    for: PreviewCatalog.items[0].id
                )
                try repository.save(PreviewCatalog.items[1], to: wantTo.id)
            }
            _ = try repository.createShelf(named: "Book Club")
            return repository
        } catch {
            fatalError("Preview library failed: \(error)")
        }
    }
}
