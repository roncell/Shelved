import Foundation

extension Dependencies {
    /// Fake data for `#Preview`s: canned catalog plus an in-memory library
    /// with a couple of saved books. Nothing touches the network or disk.
    static func preview(
        catalog: any MediaCatalog = PreviewCatalog(),
        series: any SeriesCatalog = PreviewSeriesCatalog(),
        library: any LibraryRepository = SwiftDataLibraryRepository.preview()
    ) -> Dependencies {
        Dependencies(catalog: catalog, series: series, library: library)
    }
}
