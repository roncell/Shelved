# Shelved — Personal Reading & Watch Tracker (iOS)

> Working name: **Shelved**. Rename freely.

## What this app is
An iOS app to track books, films, and TV shows. Users search public catalogs, save items to shelves, rate and review them, and see stats about their habits.

This is a **learning project**. The goal is to practice production-grade iOS architecture, not just ship features. When helping on this project, Claude should:
- Explain the *why* behind architectural choices, not only the code.
- Prefer small, reviewable steps over large dumps of code.
- Point out trade-offs and alternatives (e.g., MVVM vs TCA) when they come up.
- Suggest a test whenever new logic is added.

## Tech stack
- **Language:** Swift 6 (strict concurrency on)
- **UI:** SwiftUI
- **State:** Observation framework (`@Observable`) with MVVM
- **Navigation:** `TabView` + one `NavigationStack` per tab, driven by a Router with `NavigationPath`
- **Networking:** `URLSession` + async/await, `Codable`
- **Persistence:** SwiftData
- **Modularization:** local Swift packages (SPM)
- **Testing:** Swift Testing for unit tests, XCUITest for a few UI flows
- **Minimum iOS:** 17 (needed for `@Observable` and SwiftData)
- **Third-party dependencies:** none at first. Add only with a clear reason.

## Data sources
| Source | Used for | Auth |
|---|---|---|
| Open Library API | Books, authors, covers | None |
| TMDB API | Films, TV shows, people | Free API key |

- Books come first (no key needed). Films/TV are added later behind the same abstraction.
- **Never commit API keys.** Keep the TMDB key in an untracked `Secrets.xcconfig` and read it through Info.plist. Add `Secrets.xcconfig` to `.gitignore` and commit a `Secrets.example.xcconfig`.

## Features
### Tabs
1. **Home** — currently reading/watching, recently added, quick stats
2. **Search** — unified search across books/films/shows, with filters and pagination
3. **Library** — shelves (Want to Read/Watch, In Progress, Finished, Abandoned, custom shelves)
4. **Stats** — items finished per month, ratings distribution, genres, streaks (Swift Charts)
5. **Settings** — appearance, data export/import, clear cache, about

### Core flows
- Search → Item Detail → Creator (author/director/actor) → their other works → Item Detail → … (unbounded depth)
- Add to shelf, change shelf, remove
- Rate (0.5–5 stars) and write a review
- Log progress (pages / episodes) and start/finish dates

## Architecture

### Layers
```
View  →  ViewModel (@Observable)  →  Repository (protocol)  →  Remote API / Local store
```
- **Views** are dumb: render state, forward user intents.
- **ViewModels** own screen state and call repositories. No `URLSession` or SwiftData calls here.
- **Repositories** are the single source of truth for a domain. They merge remote and local data.
- **Data sources** (API clients, SwiftData store) are hidden behind repositories.

### Domain model
Keep the domain independent of any API's JSON shape. Map DTOs → domain models at the data layer.

```swift
enum MediaKind: String, Codable { case book, film, show }

struct MediaItem: Identifiable, Hashable {
    let id: MediaID          // e.g. .openLibrary("OL123W") / .tmdb(.film, 550)
    let kind: MediaKind
    let title: String
    let creators: [CreatorSummary]
    let coverURL: URL?
    let year: Int?
    let summary: String?
}

struct Creator: Identifiable, Hashable { /* author / director / actor */ }

// Persisted (SwiftData @Model)
LibraryEntry  — mediaID, shelf, rating, review, progress, startedAt, finishedAt
Shelf         — name, isSystem, sortOrder
```

### Navigation
- One `Router` per tab, each holding its own `NavigationPath`.
- Routes are a type-safe enum:
  ```swift
  enum Route: Hashable {
      case itemDetail(MediaID)
      case creator(CreatorID)
      case shelf(ShelfID)
      case review(MediaID)
  }
  ```
- Views push with `router.push(.creator(id))`, never with inline `NavigationLink(destination:)`.
- A single `destination(for:)` builder maps `Route` → View.
- Deep links (`shelved://item/...`) are parsed into `[Route]` and applied to the right tab.
- Tapping the active tab again pops to the root.

### Dependency injection
- Every service is a protocol (`MediaSearching`, `LibraryStoring`, …).
- A `Dependencies` container is built at app launch and passed through the SwiftUI `Environment`.
- Previews and tests inject mocks/fakes.

### Error and loading state
Every async screen uses a shared state type:
```swift
enum Loadable<Value> { case idle, loading, loaded(Value), failed(Error) }
```
Every screen must handle empty, loading, error, and offline states.

## Project structure (target)
```
Shelved/                     # App target: entry point, tab shell, DI wiring
Packages/
  Core/                      # Domain models, Loadable, shared utilities
  DesignSystem/              # Colors, typography, reusable components (RatingView, CoverImage…)
  Networking/                # HTTP client, endpoints, DTOs
    OpenLibrary/
    TMDB/
  Persistence/               # SwiftData models, store
  Data/                      # Repositories (merge remote + local)
  Navigation/                # Route, Router, deep link parsing
  Features/
    HomeFeature/
    SearchFeature/
    DetailFeature/
    CreatorFeature/
    LibraryFeature/
    StatsFeature/
    SettingsFeature/
ShelvedTests/
ShelvedUITests/
```
**Dependency rules:** Features depend on Core, DesignSystem, Navigation, and repository *protocols*. Features never import each other or Networking/Persistence directly. Only the app target wires concrete implementations.

> Start everything in the app target (Phase 1–4), then extract packages in Phase 7. Feeling the pain before modularizing is part of the lesson.

## Conventions
- One type per file. Files named after the type.
- ViewModels: `<Screen>ViewModel`, marked `@MainActor @Observable`.
- No force unwraps outside tests.
- `async`/`await` only. No completion handlers, no Combine unless there's a specific reason.
- Use `#Preview` for every view, with mock data.
- Strings in a String Catalog from day one.
- Accessibility: every interactive element has a label, and layouts support Dynamic Type.
- Commit messages: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`.

## Roadmap

### Phase 1 — App shell & navigation
- [ ] Create the Xcode project (SwiftUI, Swift 6, iOS 17+)
- [ ] `TabView` with 5 tabs and placeholder screens
- [ ] `Route` enum + `Router` per tab, `destination(for:)` builder
- [ ] Push placeholder detail → creator → detail to prove unbounded navigation works
- [ ] Re-tap the tab to pop to root
- **Learn:** `NavigationStack`, `NavigationPath`, value-based navigation, why routers beat inline `NavigationLink`

### Phase 2 — Networking & search (books)
- [ ] Generic `HTTPClient` + `Endpoint` type
- [ ] Open Library search, work detail, and author endpoints, with DTOs
- [ ] DTO → `MediaItem` mapping
- [ ] Search screen: debounced query, results list, pagination, `Loadable` states
- [ ] Detail screen with cover images
- **Learn:** async/await, `Codable`, structured concurrency, task cancellation on new queries, separating DTOs from the domain

### Phase 3 — Detail & creator flow
- [ ] Item detail screen (full metadata, add-to-shelf button)
- [ ] Creator screen listing their other works
- [ ] Infinite drill-down: detail → creator → work → …
- **Learn:** passing IDs (not objects) through routes, each screen loading its own data

### Phase 4 — Library & persistence
- [ ] SwiftData models: `LibraryEntry`, `Shelf`
- [ ] `LibraryRepository` protocol + SwiftData implementation
- [ ] Shelves screen, shelf detail, move/remove items
- [ ] Ratings, reviews, progress, dates
- [ ] Offline: saved items show without a network connection
- **Learn:** SwiftData modeling, the repository pattern, keeping persistence out of views

### Phase 5 — Dependency injection & tests
- [ ] Protocols for every service, `Dependencies` container in the Environment
- [ ] Mocks/fakes for previews and tests
- [ ] Unit tests: mappers, ViewModels, repositories
- [ ] 2–3 UI tests (search → add to shelf → appears in Library)
- **Learn:** testability as a design goal, the difference between fakes and mocks

### Phase 6 — Films & TV (TMDB)
- [ ] TMDB client behind the same search/detail protocols
- [ ] Unified search across sources, with kind filters
- [ ] Creator screen supports directors/actors
- [ ] Secure API key handling
- **Learn:** whether the abstraction holds up. If adding a second source hurts, refactor and note why.

### Phase 7 — Modularization
- [ ] Extract packages per the target structure above
- [ ] Enforce dependency rules (features don't import each other)
- [ ] Measure build-time impact
- **Learn:** module boundaries, access control (`public`/`package`/`internal`), why big apps modularize

### Phase 8 — Stats, Home & polish
- [ ] Stats screen with Swift Charts
- [ ] Home dashboard
- [ ] Deep links
- [ ] Home screen widget (WidgetKit) showing current reads/watches
- [ ] Settings: export/import library as JSON
- [ ] Accessibility and Dynamic Type pass
- [ ] Ship to TestFlight
- **Learn:** app extensions, sharing code with a widget, release process

### Stretch goals
- [ ] Rewrite one feature (e.g., Search) in The Composable Architecture and compare with MVVM
- [ ] iCloud sync via CloudKit
- [ ] iPad layout with `NavigationSplitView`
- [ ] Barcode scanning to add books by ISBN

## Decision log
Record notable architecture decisions here as the project evolves.

| Date | Decision | Why |
|---|---|---|
| 2026-10-18 | MVVM + Router + Repository, SwiftData, no third-party deps to start | Learn the fundamentals before reaching for frameworks |
| 2026-10-18 | Books (Open Library) before Films/TV (TMDB) | No API key needed; tests the abstraction when the second source arrives |
| 2026-10-20 | `TabCoordinator` owns selected tab + one `Router` per tab; routes carry IDs only | Per-tab stacks survive tab switches; re-tap pop-to-root is testable without UI |
