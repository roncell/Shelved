import Core
import Foundation

extension InMemoryLibraryRepository {
    /// A library with a couple of saved items and a custom shelf, for `#Preview`s.
    public static func preview() -> InMemoryLibraryRepository {
        let repository = InMemoryLibraryRepository()
        do {
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
                try repository.save(PreviewCatalog.show, to: wantTo.id)
            }
            _ = try repository.createShelf(named: "Book Club")
        } catch {
            assertionFailure("Preview library failed: \(error)")
        }
        return repository
    }
}
