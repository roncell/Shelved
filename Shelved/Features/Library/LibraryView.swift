import SwiftUI

struct LibraryView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: LibraryViewModel
    @State private var isNamingShelf = false
    @State private var newShelfName = ""

    /// Phase 5 replaces the `.shared` default with a container in the Environment.
    init(library: any LibraryRepository = SwiftDataLibraryRepository.shared) {
        _viewModel = State(initialValue: LibraryViewModel(library: library))
    }

    var body: some View {
        content
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Shelf", systemImage: "plus") {
                        newShelfName = ""
                        isNamingShelf = true
                    }
                }
            }
            .alert("New Shelf", isPresented: $isNamingShelf) {
                TextField("Name", text: $newShelfName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    Task { await viewModel.createShelf(named: newShelfName) }
                }
            }
            .alert(
                "Couldn't update shelves",
                isPresented: Binding(
                    get: { viewModel.actionError != nil },
                    set: { if !$0 { viewModel.actionError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.actionError ?? "")
            }
            // Re-runs whenever the tab or this screen reappears, so counts stay fresh.
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't load your library", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }

        case .loaded:
            List {
                Section {
                    ForEach(viewModel.systemShelves) { shelf in
                        shelfRow(shelf)
                    }
                }

                Section {
                    ForEach(viewModel.customShelves) { shelf in
                        shelfRow(shelf)
                    }
                    .onDelete { offsets in
                        let shelves = offsets.map { viewModel.customShelves[$0] }
                        Task {
                            for shelf in shelves { await viewModel.deleteShelf(shelf) }
                        }
                    }
                } header: {
                    Text("My Shelves")
                } footer: {
                    if viewModel.customShelves.isEmpty {
                        Text("Tap + to make your own shelf, like “Book Club” or “Summer 2026”.")
                    } else {
                        Text("Deleting a shelf moves its books to Want to Read.")
                    }
                }
            }
        }
    }

    private func shelfRow(_ shelf: ShelfSummary) -> some View {
        Button {
            router.push(.shelf(shelf.id))
        } label: {
            LabeledContent {
                Text(shelf.itemCount, format: .number)
            } label: {
                Label(shelf.name, systemImage: shelf.systemImage)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityHint(Text("Shows the books on this shelf"))
    }
}

#Preview {
    NavigationStack {
        LibraryView(library: SwiftDataLibraryRepository.preview())
            .withRouteDestinations()
    }
    .environment(Router())
}
