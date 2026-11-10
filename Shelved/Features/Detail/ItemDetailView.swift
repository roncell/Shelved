import SwiftUI

struct ItemDetailView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: ItemDetailViewModel

    init(id: MediaID, catalog: any MediaCatalog = OpenLibraryCatalog()) {
        _viewModel = State(initialValue: ItemDetailViewModel(id: id, catalog: catalog))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
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
            DetailContent(detail: detail) { creatorID in
                router.push(.creator(creatorID))
            }
        }
    }
}

/// The loaded layout. Kept separate so it only deals with a `MediaDetail`,
/// not with loading states.
private struct DetailContent: View {
    let detail: MediaDetail
    let onCreatorTap: (CreatorID) -> Void

    var body: some View {
        List {
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
                        addToShelfButton
                            .padding(.top, 6)
                    }
                }
            }

            if !detail.creators.isEmpty {
                Section("By") {
                    ForEach(detail.creators) { creator in
                        Button(creator.name) { onCreatorTap(creator.id) }
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

    /// Visible now so the layout is settled; shelves (and this action) arrive
    /// with persistence in Phase 4. Disabled rather than a silent no-op, so it
    /// never looks like it saved something.
    private var addToShelfButton: some View {
        Button {
            // Phase 4: open the shelf picker.
        } label: {
            Label("Add to Shelf", systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)
        .disabled(true)
        .accessibilityHint(Text("Shelves are coming soon"))
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

#Preview {
    NavigationStack {
        ItemDetailView(id: .openLibraryWork("OL893414W"), catalog: PreviewCatalog())
            .withRouteDestinations()
    }
    .environment(Router())
}
