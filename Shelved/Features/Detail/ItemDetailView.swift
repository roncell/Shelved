import SwiftUI

struct ItemDetailView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: ItemDetailViewModel

    init(
        id: MediaID,
        catalog: any MediaCatalog = OpenLibraryCatalog(),
        library: any LibraryRepository = SwiftDataLibraryRepository.shared
    ) {
        _viewModel = State(initialValue: ItemDetailViewModel(id: id, catalog: catalog, library: library))
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
                Label("Couldn't load this book", systemImage: "exclamationmark.triangle")
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
                        ShelfMenu(
                            shelves: viewModel.shelves,
                            current: viewModel.libraryItem,
                            onSelect: { shelfID in Task { await viewModel.addToShelf(shelfID) } },
                            onRemove: { Task { await viewModel.removeFromLibrary() } }
                        )
                        .padding(.top, 6)
                    }
                }
            }

            if let libraryItem = viewModel.libraryItem {
                YourNotesSection(item: libraryItem) {
                    router.push(.review(libraryItem.id))
                }
            }

            if !detail.creators.isEmpty {
                Section("By") {
                    ForEach(detail.creators) { creator in
                        Button(creator.name) { router.push(.creator(creator.id)) }
                            .accessibilityHint(Text("Shows other works by this author"))
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
    NavigationStack {
        ItemDetailView(
            id: PreviewCatalog.items[0].id,
            catalog: PreviewCatalog(),
            library: SwiftDataLibraryRepository.preview()
        )
        .withRouteDestinations()
    }
    .environment(Router())
}

#Preview("Not saved") {
    NavigationStack {
        ItemDetailView(
            id: PreviewCatalog.items[0].id,
            catalog: PreviewCatalog(),
            library: (try? SwiftDataLibraryRepository.inMemory()) ?? .preview()
        )
        .withRouteDestinations()
    }
    .environment(Router())
}
