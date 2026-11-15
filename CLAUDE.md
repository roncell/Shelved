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
3. **Library** — shelves (Want to Read/Watch, In Progress, Finished, custom shelves)
4. **Stats** — items finished per month, ratings distribution, genres, streaks (Swift Charts)
5. **Settings** — appearance, data export/import, clear cache, about

### Core flows
- Search → Item Detail → Creator (author/director/actor) → their other works → Item Detail → … (unbounded depth)
- Search or Item Detail → Series → every book in reading order → Item Detail
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
enum MediaID   { case openLibraryWork(String), tmdbFilm(Int), tmdbShow(Int) }
enum CreatorID { case openLibraryAuthor(String), tmdbPerson(Int) }

struct MediaItem {      // search results / lists
    let id: MediaID, kind: MediaKind, title: String
    let creators: [CreatorSummary], coverURL: URL?, year: Int?
}
struct MediaDetail {    // detail screen: MediaItem fields + summary, subjects
    ...
    let summary: String?, subjects: [String]
}
struct CreatorSummary { let id: CreatorID; let name: String }
struct SearchPage { let items: [MediaItem]; let hasMore: Bool }

protocol MediaCatalog {   // Data/ — what ViewModels depend on
    func search(query: String, kind: MediaKind?, page: Int) async throws -> SearchPage
    func detail(for id: MediaID) async throws -> MediaDetail
    func creator(for id: CreatorID) async throws -> CreatorDetail
    func works(by id: CreatorID, page: Int) async throws -> SearchPage
}
// OpenLibraryCatalog and TMDBCatalog are the real sources; CombinedCatalog
// (Data/) routes between them. PreviewCatalog / StubCatalog are fakes.

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
      case series(SeriesID)      // Phase 5.5
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

### Concurrency
- Swift 6 language mode, strict concurrency **Complete**. Works with either "Default Actor Isolation" setting (new Xcode projects default to `MainActor`).
- UI-facing classes (Routers, ViewModels) are `@MainActor`.
- Plain values and networking types (domain models, DTOs, `Endpoint`, `HTTPClient`, catalogs, mappers) are marked `nonisolated` and `Sendable`, so they can be decoded and passed between threads regardless of the default isolation.
- Async work is tied to view lifetime with `.task` / `.task(id:)`, so leaving a screen cancels its requests. On cancellation, don't show an error.

## Project structure
```
Shelved/                     # App target: entry point, tab shell, DI wiring, RouteDestinations
Packages/                    # One local package (ShelvedKit), one target per folder below
  Package.swift              # The dependency graph, in one place
  Core/                      # Domain models, Loadable, UserFacingError, shared utilities
  DesignSystem/              # Reusable components (RatingView, CoverImage, MediaItemRow…)
  Data/                      # Service protocols, CombinedCatalog, fakes (PreviewCatalog, InMemoryLibraryRepository)
  Networking/                # HTTP client, endpoints, DTOs, catalogs
    OpenLibrary/
    TMDB/
    Wikidata/
  Persistence/               # SwiftData models, SwiftDataLibraryRepository
  Navigation/                # Route, Router, AppTab, TabCoordinator
  Features/
    HomeFeature/  SearchFeature/  DetailFeature/  CreatorFeature/  SeriesFeature/
    LibraryFeature/  ReviewFeature/  StatsFeature/  SettingsFeature/
Scripts/check-module-imports.sh  # Enforces the dependency rules on every build
ShelvedTests/
ShelvedUITests/
```
**Dependency rules:** Features depend on Core, DesignSystem, Navigation, and Data (service *protocols* and fakes). Features never import each other or Networking/Persistence directly. Networking and Persistence implement Data's protocols. Only the app target wires concrete implementations.

Xcode doesn't enforce `Package.swift` dependencies (all package modules share one build folder, so an undeclared `import` still compiles). The `ModuleRules` target runs `Scripts/check-module-imports.sh` before every app build and fails it on a forbidden import. Its rule table must match `Package.swift`.

> Start everything in the app target (Phase 1–4), then extract packages in Phase 7. Feeling the pain before modularizing is part of the lesson.

## Conventions
- One type per file. Files named after the type.
- ViewModels: `<Screen>ViewModel`, marked `@MainActor @Observable`.
- No force unwraps outside tests.
- `async`/`await` only. No completion handlers, no Combine unless there's a specific reason.
- Use `#Preview` for every view, with mock data (`PreviewCatalog`).
- Strings in a String Catalog from day one.
- Accessibility: every interactive element has a label, and layouts support Dynamic Type.
- Commit messages: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`.
- Access control across modules: `public` for what the app target uses (domain types, service protocols, screen views and their `init`s); `package` for what only other package modules use (DesignSystem); `internal` for the rest (ViewModels, DTOs, mappers), which tests reach with `@testable import`. Public structs need an explicit `public init`: the synthesized memberwise one is internal.

## Roadmap

### Phase 1 — App shell & navigation
- [x] Create the Xcode project (SwiftUI, Swift 6, iOS 17+)
- [x] `TabView` with 5 tabs and placeholder screens
- [x] `Route` enum + `Router` per tab, `destination(for:)` builder
- [x] Push placeholder detail → creator → detail to prove unbounded navigation works
- [x] Re-tap the tab to pop to root
- **Learn:** `NavigationStack`, `NavigationPath`, value-based navigation, why routers beat inline `NavigationLink`

### Phase 2 — Networking & search (books)
- [x] Generic `HTTPClient` + `Endpoint` type
- [x] Open Library search, work detail, and author endpoints, with DTOs
- [x] DTO → `MediaItem` mapping
- [x] Search screen: debounced query, results list, pagination, `Loadable` states
- [x] Detail screen with cover images
- **Learn:** async/await, `Codable`, structured concurrency, task cancellation on new queries, separating DTOs from the domain

### Phase 3 — Detail & creator flow
- [x] Item detail screen (full metadata, add-to-shelf button — disabled until Phase 4 wires it to shelves)
- [x] Creator screen listing their other works
- [x] Infinite drill-down: detail → creator → work → …
- **Learn:** passing IDs (not objects) through routes, each screen loading its own data

### Phase 4 — Library & persistence
- [x] SwiftData models: `LibraryEntry`, `Shelf`
- [x] `LibraryRepository` protocol + SwiftData implementation
- [x] Shelves screen, shelf detail, move/remove items
- [x] Ratings, reviews, progress, dates
- [x] Offline: saved items show without a network connection
- **Learn:** SwiftData modeling, the repository pattern, keeping persistence out of views

### Phase 5 — Dependency injection & tests
- [x] Protocols for every service, `Dependencies` container in the Environment
- [x] Mocks/fakes for previews and tests
- [x] Unit tests: mappers, ViewModels, repositories
- [x] 2–3 UI tests (search → add to shelf → appears in Library)
- **Learn:** testability as a design goal, the difference between fakes and mocks

### Phase 5.5 — Book series
Goal: searching "game of thrones" offers the whole *A Song of Ice and Fire* series, and every book in a series links to the others in reading order.
- [x] **Spike first:** confirm a series source with good coverage. Open Library's series data is sparse free text. Candidate: **Wikidata** (free, no key): "part of the series" (P179) + "series ordinal" (P1545), linked back to Open Library work IDs via P648. Try 5–10 known series (ASOIAF, Harry Potter, Dune, Discworld, The Expanse) and record what's missing
  - **Result (2026-11-14):** Wikidata works. Harry Potter 7/7, ASOIAF 1–7, The Expanse 1–9, Dune 1–6 ordered with Open Library IDs; Discworld 42 of 65 numbered. Problems found: Wikidata often holds a stale (merged) work ID (Dune is filed under `OL893415W`), so matching falls back to author ID + English title; translations share positions; some members have edition (`…M`) IDs, no English label, or no position. Covers come from one Open Library `key:(… OR …)` search.
- [x] Domain: `SeriesID` (enum, a case per source), `Series` (name, ordered entries), `SeriesEntry` (position, title, optional work ID), `SeriesMembership` (series ID, name, position, total). Membership lives on `ItemDetailViewModel`, not `MediaDetail` (see decision log)
- [x] `SeriesCatalog` protocol + real implementation + fake; series lookups cached (they rarely change)
- [x] Detail screen: "Book 1 of 5 · A Song of Ice and Fire" row → Series screen
- [x] Series screen (`Route.series`): books in order with covers, years and your shelf status; "Add all to Want to Read"
- [x] Search: when a top result belongs to a series, show a series card above the results
- [x] Hide all series UI when no data is found; never show a wrong or partial order as complete
- **Learn:** adding a third data source behind a protocol, joining two APIs by ID, caching, designing UI that degrades gracefully when data is missing

### Phase 6 — Films & TV (TMDB)
- [x] TMDB client behind the same search/detail protocols
- [x] Unified search across sources, with kind filters
- [x] Creator screen supports directors/actors
- [x] Secure API key handling
- **Learn:** whether the abstraction holds up. If adding a second source hurts, refactor and note why.

### Phase 7 — Modularization
- [x] Extract packages per the target structure above
- [x] Enforce dependency rules (features don't import each other)
- [x] Measure build-time impact
  - **Result (2026-11-14, iPhone 18 Pro simulator, Debug, M1 Pro):** clean build 14.0 s → 17–18 s; changing a feature's interface 4.2 s → 4.6 s; changing a Core type's interface 4.1 s → 11 s. At this size modularizing makes builds *slower*: an interface change in a low module now rebuilds every module above it, where one module's incremental build only recompiled the files that used it. The payoff is boundaries (enforced dependencies, smaller public surfaces) and, in much bigger apps, parallel builds and skipping untouched modules.
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
- [ ] iCloud sync via CloudKit (now part of Version 2, phase V2.0)
- [ ] iPad layout with `NavigationSplitView`
- [ ] Barcode scanning to add books by ISBN

## Version 2 — Book clubs & curated shelves
Planned in **`PLAN-V2.md`**: book clubs with friends (V2.0–V2.5) and app-curated shelves from genres and your interests (V2.6–V2.7). Don't start it until Version 1 (Phases 1–8) ships, and don't add club features to V1 code.
When V1 work touches persistence, keep the `@Model`s CloudKit-shaped (see the 2026-11-11 decision), since V2 syncs them.

## Decision log
Record notable architecture decisions here as the project evolves.

| Date | Decision | Why |
|---|---|---|
| 2026-10-18 | MVVM + Router + Repository, SwiftData, no third-party deps to start | Learn the fundamentals before reaching for frameworks |
| 2026-10-18 | Books (Open Library) before Films/TV (TMDB) | No API key needed; tests the abstraction when the second source arrives |
| 2026-10-20 | `TabCoordinator` owns selected tab + one `Router` per tab; routes carry IDs only | Per-tab stacks survive tab switches; re-tap pop-to-root is testable without UI |
| 2026-10-30 | `MediaID`/`CreatorID` are enums with a case per source | Source is part of identity; adding TMDB makes the compiler flag every switch |
| 2026-10-30 | Separate `MediaItem` (lists) and `MediaDetail` (detail) | Search results lack summary/subjects; avoids "sometimes nil" fields |
| 2026-10-30 | `MediaCatalog` protocol injected via view `init` default argument | Testable now; replaced by an Environment `Dependencies` container in Phase 5 |
| 2026-10-30 | Debounce with `.task(id: query)` + `Task.sleep`, no Combine | SwiftUI cancels the stale task on each keystroke; cancellation propagates to URLSession |
| 2026-10-30 | `AsyncImage` for covers, wrapped in `CoverImage` | No dependency yet; no disk cache, so swap the loader inside `CoverImage` if it becomes a problem |
| 2026-11-06 | Search-as-you-type: last word sent as a prefix (`du` → `du*`) in `OpenLibraryAPI.prefixQuery` | Open Library matches whole words; the wildcard is Open Library query syntax, so it lives in the Open Library layer, not the ViewModel |
| 2026-11-09 | Catalog follows Open Library `/type/redirect` records (max 3 hops) and returns the canonical ID | Merged records leave stale IDs behind (Home's Dune `OL893415W` was one); routes, deep links and saved entries all carry IDs |
| 2026-11-09 | Creator works via `search.json?q=author_key:…`, not `/authors/{id}/works.json` | Popularity ranking, covers and years, and reuses the search DTO/mapper; the works endpoint sorts by last edit with no covers |
| 2026-11-09 | Creator screen loads profile + first works page with `async let`; works fail independently | Two fixed calls in parallel; a failed works list shouldn't hide the profile |
| 2026-11-09 | Shared list pieces (`MediaItemRow`, `LoadMoreFooter`, `ExpandableText`) live in DesignSystem/ | Search and Creator both use them, and features must not import each other once modularized |
| 2026-11-11 | `LibraryRepository` returns value types (`ShelfSummary`, `LibraryItem`), never `@Model` objects; no `@Query` | Keeps SwiftData out of views/ViewModels. Cost: screens re-fetch on every appear instead of auto-updating |
| 2026-11-11 | Repository is `@MainActor` on the main context, but its protocol methods are `async` | Simple now; moving to a background `@ModelActor` later changes no call sites |
| 2026-11-11 | `@Model`s are CloudKit-shaped: defaults everywhere, optional relationships, no `@Attribute(.unique)` | CloudKit sync is a stretch goal and model changes need migrations; uniqueness is enforced in the repository |
| 2026-11-11 | Entries store a media snapshot; IDs stored as `storageKey` strings ("openlibrary:work:OL…") | Shelves render offline; `#Predicate` can't match inside an enum with associated values |
| 2026-11-11 | One shelf per item; deleting a custom shelf moves its items to Want to Read | Matches the spec's single `shelf` field; deleting a shelf shouldn't delete ratings |
| 2026-11-11 | Detail falls back to the saved snapshot when the catalog fails | Saved books open offline; done in `ItemDetailViewModel` for now, a candidate for a merging repository later |
| 2026-11-11 | Repository injected as `SwiftDataLibraryRepository.shared` default argument | Same stopgap as the catalog; Phase 5 replaces both with an Environment container. Known gap: screens pushed from a preview use the real store |
| 2026-11-13 | Version 2 = book clubs with friends + curated shelves, planned in `PLAN-V2.md` | Keeps V1 scope stable; both build on the finished library and TMDB support |
| 2026-11-13 | Removed the Abandoned system shelf | Not needed; a custom shelf covers it. Existing stores: an empty legacy row is deleted, one with items becomes a custom "Abandoned" shelf so nothing is lost |
| 2026-11-13 | Book series added to V1 as Phase 5.5, after DI & tests | Series lookups need a new source behind a protocol, easier once the Phase 5 container exists. Numbered 5.5 so existing "Phase 6/7/8" references in code and docs stay valid |
| 2026-11-14 | `Dependencies` (`@MainActor @Observable` class) injected with `.environment(_:)`; read only by `TabStack` and `RouteDestinations`, which pass services into screen `init`s | Composition root in one place; screens declare exactly what they need and still create their ViewModel in `init`. No default value: a missing container crashes on first push instead of silently using the real store |
| 2026-11-14 | Kept the names `MediaCatalog` / `LibraryRepository` instead of `MediaSearching` / `LibraryStoring` | Already protocols with fakes; renaming would be churn with no testability gain |
| 2026-11-14 | `SwiftDataLibraryRepository.shared` removed; `Dependencies.live()` creates the one on-disk repository | No global left for a preview or test to reach by accident |
| 2026-11-14 | UI tests launch with `-ui-testing` → `PreviewCatalog` + empty in-memory library (Debug builds only) | Offline, fast, clean slate per test. Cost: a small test hook in app code, compiled out of Release |
| 2026-11-14 | Test doubles: stubs (`StubCatalog`, `FailingLibraryRepository`), a spy (`SpyCatalog`), fakes (in-memory repository, `PreviewCatalog`); no mocks | Spies keep assertions in the test where they're readable; mocks that verify themselves add a framework-like layer for little gain here |
| 2026-11-14 | TMDB IDs are `.tmdbFilm(Int)` / `.tmdbShow(Int)`, not `.tmdb(MediaKind, Int)` | The planned shape allows `.tmdb(.book, 5)`; TMDB numbers films and shows separately anyway |
| 2026-11-14 | `CombinedCatalog` (Data/) routes `detail`/`creator`/`works` by an exhaustive switch on the ID; `search` gains a `kind` filter | Screens stay single-source; a third source makes the compiler point at the routing. The abstraction held: only `search` needed a new parameter |
| 2026-11-14 | Combined search merges sources round-robin and returns partial results if one source fails | Relevance scores from two APIs aren't comparable. Cost: in "All", films silently disappear when TMDB is down or has no token (the Films scope shows the error) |
| 2026-11-14 | TMDB "Read Access Token" sent as a Bearer header, from untracked `Config/Secrets.xcconfig` → Info.plist → `AppSecrets` | Out of git and out of URLs/logs. Still readable from the shipped app; real protection needs a proxy server. No token → `UnavailableCatalog`, books keep working |
| 2026-11-14 | A person's TMDB works come back as one page (combined credits, talk/news shows dropped) | TMDB doesn't page combined credits; a few hundred rows is fine for a lazy List |
| 2026-11-14 | Shelf names per kind: "Want to Read" / "Want to Watch" next to an item, "Want to Read/Watch" in the Library tab; films don't log progress, shows log episodes | Shelves are shared across kinds; names come from code, so no migration |
| 2026-11-14 | Series from Wikidata (`WikidataSeriesCatalog`), matched by Open Library work ID **or** author ID + English title | Spike showed good coverage; the fallback is needed because Wikidata keeps stale merged work IDs |
| 2026-11-14 | Series membership is loaded by `ItemDetailViewModel` from `SeriesCatalog`, not added to `MediaDetail` | `MediaDetail` comes from `MediaCatalog`; putting a second source in it would make Open Library code call Wikidata. Separate protocol, separate failure: a failed lookup just hides the row |
| 2026-11-14 | Covers for a series via a new batch `MediaCatalog.items(for:)` (one Open Library search; merged IDs fetched one by one) | Joining two APIs by ID without N requests per series; results keyed by the requested ID so stale IDs still map to canonical items |
| 2026-11-14 | Series cleanup: numeric positions only, one book per position (prefer one with a work ID, a real title, the lowest Q-number); "of N" only when positions run 1…N with no gaps | Wikidata is crowd-edited; a wrong total is worse than none |
| 2026-11-14 | `WikidataSeriesCatalog` is an actor with an in-memory cache (including "no series") | Search, Detail and Series ask about the same book; series rarely change. No disk cache yet |
| 2026-11-14 | "Add all to Want to Read" skips books already saved anywhere | Re-adding would move a finished book back to Want to Read |
| 2026-11-14 | One local package (`Packages/Package.swift`) with a target per module, not one package per module | The whole dependency graph is readable in one file; folders still match the planned structure. Separate packages would only matter for versioning or sharing outside this repo |
| 2026-11-14 | Data holds the service protocols; Networking and Persistence depend on Data and implement them | Dependency inversion: features see protocols without being able to reach a concrete source |
| 2026-11-14 | `Error.userMessage` asks a `UserFacingError` protocol (Core) instead of listing error types | Core is the bottom layer and can't import `LibraryError` (Data) or `NetworkError` (Networking); each error describes itself where it's declared |
| 2026-11-14 | Feature previews use `InMemoryLibraryRepository` (a fake in Data), checked against SwiftData by `LibraryRepositoryContractTests` | Features can't import Persistence. A fake that drifts would make previews lie, so both implementations run the same tests. Supersedes "previews use the real repository on a throwaway store" |
| 2026-11-14 | Feature previews render one screen; pushes inside them go nowhere. `RouteDestinations` moved to the app target | Mapping a route to a screen needs every feature, and only the app may import them all. `RootTabView`'s preview still navigates everywhere |
| 2026-11-14 | Dependency rules enforced by a build-time script (`ModuleRules` aggregate target), not by Xcode or a unit test | Xcode compiles undeclared imports of sibling package modules. A unit test reading sources from the simulator hung on macOS privacy protection (the repo is in ~/Downloads). Cost: the rule table is written twice (script + manifest) |
| 2026-11-14 | Networking exposes only the three catalogs (`public init()`); `HTTPClient`, DTOs and mappers stay internal | The app needs nothing else, and tests use `@testable import`. Public `init(client:)` would leak `HTTPClient` into the public API |
| 2026-11-14 | `Core.LibraryItem` spelled out in three views | SwiftUI also declares `LibraryItem`. Inside the app target our type shadowed it; across modules the two imports tie |
| 2026-11-14 | Strings in packages still resolve against the app's `Localizable.xcstrings` (main bundle); no per-package catalogs yet | English-only, so behavior is identical. Per-package catalogs mean passing `bundle: .module` to every `Text`; worth it when a second language arrives |
