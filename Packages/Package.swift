// swift-tools-version: 6.0
import PackageDescription

/// Every module except the app shell, in one local package.
///
/// One manifest, many targets: the whole dependency graph is readable in
/// this file, and each target can only `import` what it lists below
/// (Xcode builds modules explicitly, so an undeclared import fails to
/// compile). The rules from CLAUDE.md, enforced here:
/// - Features depend on Core, DesignSystem, Navigation and Data (protocols).
/// - Features never depend on each other, Networking, or Persistence.
/// - Only the app target sees every module, and wires concrete types.
///
/// Data defines the service protocols; Networking and Persistence
/// implement them. So the arrows point *into* Data, not out of it
/// (dependency inversion), and Data never imports a concrete source.
let package = Package(
    name: "ShelvedKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Navigation", targets: ["Navigation"]),
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
        .library(name: "SearchFeature", targets: ["SearchFeature"]),
        .library(name: "DetailFeature", targets: ["DetailFeature"]),
        .library(name: "CreatorFeature", targets: ["CreatorFeature"]),
        .library(name: "SeriesFeature", targets: ["SeriesFeature"]),
        .library(name: "LibraryFeature", targets: ["LibraryFeature"]),
        .library(name: "ReviewFeature", targets: ["ReviewFeature"]),
        .library(name: "StatsFeature", targets: ["StatsFeature"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
    ],
    targets: [
        // Domain models and shared utilities. Depends on nothing.
        .target(name: "Core", path: "Core"),

        // Reusable views. No services, no navigation.
        .target(name: "DesignSystem", dependencies: ["Core"], path: "DesignSystem"),

        // Service protocols (MediaCatalog, SeriesCatalog, LibraryRepository),
        // the source-routing CombinedCatalog, and fakes for previews.
        .target(name: "Data", dependencies: ["Core"], path: "Data"),

        // HTTP client plus Open Library, TMDB and Wikidata.
        .target(name: "Networking", dependencies: ["Core", "Data"], path: "Networking"),

        // SwiftData models and the on-disk LibraryRepository.
        .target(name: "Persistence", dependencies: ["Core", "Data"], path: "Persistence"),

        // Route, Router, tabs.
        .target(name: "Navigation", dependencies: ["Core"], path: "Navigation"),

        feature("HomeFeature"),
        feature("SearchFeature"),
        feature("DetailFeature"),
        feature("CreatorFeature"),
        feature("SeriesFeature"),
        feature("LibraryFeature"),
        feature("ReviewFeature"),
        feature("StatsFeature"),
        feature("SettingsFeature"),
    ]
)

/// Every feature gets the same four dependencies and nothing else.
func feature(_ name: String) -> Target {
    .target(
        name: name,
        dependencies: ["Core", "DesignSystem", "Navigation", "Data"],
        path: "Features/\(name)"
    )
}
