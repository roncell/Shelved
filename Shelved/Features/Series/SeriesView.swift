import SwiftUI

struct SeriesView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: SeriesViewModel

    init(id: SeriesID, series: any SeriesCatalog, catalog: any MediaCatalog, library: any LibraryRepository) {
        _viewModel = State(initialValue: SeriesViewModel(id: id, series: series, catalog: catalog, library: library))
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
                Label("Couldn't load this series", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }

        case .loaded(let series):
            List {
                if viewModel.unsavedCount > 0 {
                    Section {
                        Button {
                            Task { await viewModel.addAllToWantTo() }
                        } label: {
                            Label("Add ^[\(viewModel.unsavedCount) book](inflect: true) to Want to Read", systemImage: "bookmark")
                        }
                    }
                }

                Section {
                    ForEach(viewModel.rows) { row in
                        if let item = row.item {
                            Button {
                                router.push(.itemDetail(item.id))
                            } label: {
                                rowContent(row, item: item)
                            }
                            .accessibilityHint(Text("Opens details"))
                        } else {
                            rowContent(row, item: nil)
                        }
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        // Never present a list with holes as if it were complete.
                        if !series.isNumberingComplete {
                            Text("Some books may be missing: the numbering for this series has gaps.")
                        }
                        Text("Series order from Wikidata.")
                    }
                }
            }
            .navigationTitle(series.name)
        }
    }

    private func rowContent(_ row: SeriesViewModel.Row, item: MediaItem?) -> some View {
        HStack(spacing: 12) {
            Text(row.entry.position)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 28)
            if let item {
                MediaItemRow(item: item)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.entry.title)
                        .font(.headline)
                    Text("Not in Open Library")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let shelfName = row.shelfName {
                Text(shelfName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let dependencies = Dependencies.preview()
    NavigationStack {
        SeriesView(
            id: PreviewSeriesCatalog.dune.id,
            series: dependencies.series, catalog: dependencies.catalog, library: dependencies.library
        )
        .withRouteDestinations()
    }
    .environment(dependencies)
    .environment(Router())
}
