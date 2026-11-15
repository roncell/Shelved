import Foundation

/// The five top-level tabs.
///
/// Using an enum (instead of raw Ints as TabView tags) gives us exhaustive
/// `switch`es: add a tab here and the compiler shows every place that needs updating.
public enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case home, search, library, stats, settings

    public var id: String { rawValue }

    public var title: LocalizedStringResource {
        switch self {
        case .home: "Home"
        case .search: "Search"
        case .library: "Library"
        case .stats: "Stats"
        case .settings: "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .home: "house"
        case .search: "magnifyingglass"
        case .library: "books.vertical"
        case .stats: "chart.bar"
        case .settings: "gearshape"
        }
    }
}
