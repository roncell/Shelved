import SwiftUI

struct ShelfView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: ShelfViewModel

    init(id: ShelfID, library: any LibraryRepository = SwiftDataLibraryRepository.shared) {
        _viewModel = State(initialValue: ShelfViewModel(id: id, library: library))
    }

    var body: some View {
        content
            .navigationTitle(viewModel.shelf?.name ?? "")
            .alert(
                "Couldn't update this shelf",
                isPresented: Binding(
                    get: { viewModel.actionError != nil },
                    set: { if !$0 { viewModel.actionError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.actionError ?? "")
            }
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
                Label("Couldn't load this shelf", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            }

        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView(
                "Nothing here yet",
                systemImage: viewModel.shelf?.systemImage ?? "books.vertical",
                description: Text("Find a book in Search and add it to this shelf.")
            )

        case .loaded(let items):
            List(items) { item in
                Button {
                    router.push(.itemDetail(item.id))
                } label: {
                    LibraryItemRow(item: item)
                }
                .accessibilityHint(Text("Opens details"))
                .swipeActions {
                    Button("Remove", systemImage: "trash", role: .destructive) {
                        Task { await viewModel.remove(item) }
                    }
                }
                .contextMenu {
                    Menu("Move To", systemImage: "arrow.right") {
                        ForEach(viewModel.otherShelves) { shelf in
                            Button(shelf.name, systemImage: shelf.systemImage) {
                                Task { await viewModel.move(item, to: shelf.id) }
                            }
                        }
                    }
                    Button("Remove from Library", systemImage: "trash", role: .destructive) {
                        Task { await viewModel.remove(item) }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    let library = SwiftDataLibraryRepository.preview()
    let inProgress = (try? library.shelves().first { $0.system == .inProgress })
    return NavigationStack {
        if let inProgress {
            ShelfView(id: inProgress.id, library: library)
                .withRouteDestinations()
        }
    }
    .environment(Router())
}
