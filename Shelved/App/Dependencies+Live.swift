import Foundation

extension Dependencies {
    /// Passed by the UI tests (`ShelvedUITests`) to swap in offline fakes.
    static let uiTestingArgument = "-ui-testing"

    /// Picks the container for this launch.
    static func forLaunch(arguments: [String] = ProcessInfo.processInfo.arguments) -> Dependencies {
        #if DEBUG
        if arguments.contains(uiTestingArgument) { return uiTesting() }
        #endif
        return live()
    }

    /// The real thing: Open Library over the network, the library on disk.
    static func live() -> Dependencies {
        Dependencies(catalog: OpenLibraryCatalog(), library: SwiftDataLibraryRepository.onDisk())
    }

    #if DEBUG
    /// Canned catalog and an empty in-memory library, so UI tests are
    /// offline, fast, and start from a clean slate every launch. Debug-only:
    /// the test hook doesn't ship in release builds.
    static func uiTesting() -> Dependencies {
        do {
            return Dependencies(catalog: PreviewCatalog(), library: try SwiftDataLibraryRepository.inMemory())
        } catch {
            fatalError("Couldn't create the UI-testing library: \(error)")
        }
    }
    #endif
}
