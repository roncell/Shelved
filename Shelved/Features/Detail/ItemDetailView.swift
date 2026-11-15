import SwiftUI

struct ItemDetailView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: ItemDetailViewModel

    init(
        id: MediaID,
        catalog: any MediaCatalog,
        series: any SeriesCatalog,
        library: any LibraryRepository
    ) {
        _viewModel = State(initialValue: ItemDetailViewModel(id: id, catalog: catalog, series: series, library: library))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "Couldn't update your library",
                isPresented: Binding(
                    get: { viewModel.actionError != nil },
                    set: { if !$0 { viewModel.actionError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.actionError ?? "")
            }
            // Tied to the view's lifetime: popping this screen cancels the load.
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't load details", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }

        case .loaded(let detail):
            DetailContent(detail: detail, viewModel: viewModel)
        }
    }
}

/// The loaded layout. Kept separate so it only deals with a `MediaDetail`,
/// not with loading states.
private struct DetailContent: View {
    let detail: MediaDetail
    let viewModel: ItemDetailViewModel
    @Environment(Router.self) private var router

    var body: some View {
        List {
            if viewModel.isShowingSavedCopy {
                Section {
                    Label("You're offline. Showing your saved copy.", systemImage: "wifi.slash")
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                }
            }

            Section {
                HStack(alignment: .top, spacing: 16) {
                    CoverImage(url: detail.coverURL, width: 110)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(detail.title)
                            .font(.title2.bold())
                        if let year = detail.year {
                            Text(String(year))
                                .foregroundStyle(.secondary)
                        }
                        if let runtime = detail.runtimeMinutes {
                            Text(Duration.seconds(runtime * 60), format: .units(allowed: [.hours, .minutes], width: .abbreviated))
                                .foregroundStyle(.secondary)
                        }
                        if let seasons = detail.seasonCount {
                            // `inflect: true` picks "1 season" / "2 seasons" by grammar rules.
                            Text("^[\(seasons) season](inflect: true)")
                                .foregroundStyle(.secondary)
                        }
                        ShelfMenu(
                            kind: detail.kind,
                            shelves: viewModel.shelves,
                            current: viewModel.libraryItem,
                            onSelect: { shelfID in Task { await viewModel.addToShelf(shelfID) } },
                            onRemove: { Task { await viewModel.removeFromLibrary() } }
                        )
                        .padding(.top, 6)
                    }
                }
            }

            if let membership = viewModel.seriesMembership {
                Section {
                    Button {
                        router.push(.series(membership.seriesID))
                    } label: {
                        Label(membership.positionText, systemImage: "books.vertical")
                    }
                    .accessibilityHint(Text("Shows every book in the series"))
                }
            }

            if let libraryItem = viewModel.libraryItem {
                YourNotesSection(item: libraryItem) {
                    router.push(.review(libraryItem.id))
                }
            }

            if !detail.creators.isEmpty {
                Section(detail.kind.creatorsHeading) {
                    ForEach(detail.creators) { creator in
                        Button(creator.name) { router.push(.creator(creator.id)) }
                            .accessibilityHint(Text("Shows their other work"))
                    }
                }
            }

            if !detail.cast.isEmpty {
                Section("Cast") {
                    ForEach(detail.cast) { credit in
                        Button {
                            router.push(.creator(credit.id))
                        } label: {
                            LabeledContent(credit.person.name, value: credit.character ?? "")
                        }
                        .foregroundStyle(.primary)
                        .accessibilityHint(Text("Shows their other work"))
                    }
                }
            }

            if let summary = detail.summary {
                Section("About") {
                    ExpandableText(summary)
                }
            }

            tagSection("Subjects", detail.subjects)
            tagSection("Places", detail.places)
            tagSection("Characters", detail.characters)
            tagSection("Time Period", detail.timePeriods)

            if !detail.links.isEmpty {
                Section("Links") {
                    ForEach(detail.links, id: \.url) { link in
                        Link(link.title, destination: link.url)
                    }
                }
            }
        }
        .navigationTitle(detail.title)
    }

    @ViewBuilder
    private func tagSection(_ title: LocalizedStringKey, _ values: [String]) -> some View {
        if !values.isEmpty {
            Section(title) {
                Text(values.formatted(.list(type: .and)))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Saved") {
    let dependencies = Dependencies.preview()
    NavigationStack {
        ItemDetailView(id: PreviewCatalog.items[0].id, catalog: dependencies.catalog, series: dependencies.series, library: dependencies.library)
            .withRouteDestinations()
    }
    .environment(dependencies)
    .environment(Router())
}

#Preview("Film") {
    let dependencies = Dependencies.preview()
    NavigationStack {
        ItemDetailView(id: PreviewCatalog.film.id, catalog: dependencies.catalog, series: dependencies.series, library: dependencies.library)
            .withRouteDestinations()
    }
    .environment(dependencies)
    .environment(Router())
}

#Preview("Not saved") {
    let dependencies = Dependencies.preview(library: (try? SwiftDataLibraryRepository.inMemory()) ?? .preview())
    NavigationStack {
        ItemDetailView(id: PreviewCatalog.items[0].id, catalog: dependencies.catalog, series: dependencies.series, library: dependencies.library)
            .withRouteDestinations()
    }
    .environment(dependencies)
    .environment(Router())
}
