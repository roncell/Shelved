import Data
import Foundation

extension Dependencies {
    /// Fake data for `#Preview`s: canned catalog plus an in-memory library
    /// with a couple of saved books. Nothing touches the network or disk.
    /// Only `RootTabView`'s preview uses it: feature previews can't see the
    /// app target, so they build their screen straight from Data's fakes.
    static func preview(
        catalog: any MediaCatalog = PreviewCatalog(),
        series: any SeriesCatalog = PreviewSeriesCatalog(),
        library: any LibraryRepository = InMemoryLibraryRepository.preview()
    ) -> Dependencies {
        Dependencies(catalog: catalog, series: series, library: library)
    }
}
