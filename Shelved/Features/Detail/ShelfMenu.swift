import SwiftUI

/// "Add to Shelf" when the item isn't saved; its current shelf (with move
/// and remove options) when it is.
struct ShelfMenu: View {
    let shelves: [ShelfSummary]
    let current: LibraryItem?
    let onSelect: (ShelfID) -> Void
    let onRemove: () -> Void

    var body: some View {
        if let current {
            Menu {
                shelfButtons(currentShelf: current.shelfID)
                Divider()
                Button("Remove from Library", systemImage: "trash", role: .destructive, action: onRemove)
            } label: {
                Label(current.shelfName, systemImage: "checkmark")
            }
            .buttonStyle(.bordered)
            .accessibilityHint(Text("Moves this book to another shelf or removes it"))
        } else {
            Menu {
                shelfButtons(currentShelf: nil)
            } label: {
                Label("Add to Shelf", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(shelves.isEmpty)
        }
    }

    @ViewBuilder
    private func shelfButtons(currentShelf: ShelfID?) -> some View {
        ForEach(shelves) { shelf in
            Button {
                onSelect(shelf.id)
            } label: {
                // A checkmark on the current shelf, the standard menu convention.
                if shelf.id == currentShelf {
                    Label(shelf.name, systemImage: "checkmark")
                } else {
                    Label(shelf.name, systemImage: shelf.systemImage)
                }
            }
            .disabled(shelf.id == currentShelf)
        }
    }
}

#Preview {
    let library = SwiftDataLibraryRepository.preview()
    let shelves = (try? library.shelves()) ?? []
    let saved = try? library.item(for: PreviewCatalog.items[0].id)
    return VStack(spacing: 20) {
        ShelfMenu(shelves: shelves, current: nil, onSelect: { _ in }, onRemove: {})
        ShelfMenu(shelves: shelves, current: saved, onSelect: { _ in }, onRemove: {})
    }
}
