import SwiftUI

struct CreatorView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: CreatorViewModel

    init(id: CreatorID, catalog: any MediaCatalog = OpenLibraryCatalog()) {
        _viewModel = State(initialValue: CreatorViewModel(id: id, catalog: catalog))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
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
                Label("Couldn't load this author", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }

        case .loaded(let creator):
            List {
                CreatorHeader(creator: creator)
                worksSection
            }
            .navigationTitle(creator.name)
        }
    }

    @ViewBuilder
    private var worksSection: some View {
        Section("Works") {
            switch viewModel.works {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)

            case .failed(let error):
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.userMessage)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await viewModel.retryWorks() }
                    }
                }

            case .loaded(let items) where items.isEmpty:
                Text("No works found.")
                    .foregroundStyle(.secondary)

            case .loaded(let items):
                ForEach(items) { item in
                    Button {
                        // Detail → creator → detail → … : each push is just an ID.
                        router.push(.itemDetail(item.id))
                    } label: {
                        MediaItemRow(item: item)
                    }
                    .accessibilityHint(Text("Opens details"))
                }
                if viewModel.hasMoreWorks {
                    LoadMoreFooter(trigger: items.count, failed: viewModel.nextPageFailed) {
                        await viewModel.loadNextPage()
                    }
                }
            }
        }
    }
}

/// Photo, name, dates, and bio. Only deals with a loaded `CreatorDetail`.
private struct CreatorHeader: View {
    let creator: CreatorDetail

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: 16) {
                CoverImage(url: creator.photoURL, width: 90, placeholderSymbol: "person.fill")
                VStack(alignment: .leading, spacing: 6) {
                    Text(creator.name)
                        .font(.title2.bold())
                    if let lifespan {
                        Text(lifespan)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        if let bio = creator.bio {
            Section("About") {
                ExpandableText(bio)
            }
        }
    }

    /// "8 October 1920 – 11 February 1986", or "Born 1950" if still living.
    private var lifespan: String? {
        switch (creator.birthDate, creator.deathDate) {
        case let (born?, died?): "\(born) – \(died)"
        case let (born?, nil): String(localized: "Born \(born)")
        case let (nil, died?): String(localized: "Died \(died)")
        case (nil, nil): nil
        }
    }
}

#Preview {
    NavigationStack {
        CreatorView(id: .openLibraryAuthor("OL79034A"), catalog: PreviewCatalog())
            .withRouteDestinations()
    }
    .environment(Router())
}
