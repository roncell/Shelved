import SwiftUI

/// "Add to Shelf" when the item isn't saved; its current shelf (with move
/// and remove options) when it is.
struct ShelfMenu: View {
    /// Picks the wording: a film's menu says "Want to Watch".
    let kind: MediaKind
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
                Label(currentShelfName(current), systemImage: "checkmark")
            }
            .buttonStyle(.bordered)
            .accessibilityHint(Text("Moves this to another shelf or removes it"))
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
                    Label(name(of: shelf), systemImage: "checkmark")
                } else {
                    Label(name(of: shelf), systemImage: shelf.systemImage)
                }
            }
            .disabled(shelf.id == currentShelf)
        }
    }

    private func name(of shelf: ShelfSummary) -> String {
        shelf.system?.name(for: kind) ?? shelf.name
    }

    private func currentShelfName(_ item: LibraryItem) -> String {
        shelves.first { $0.id == item.shelfID }.map(name(of:)) ?? item.shelfName
    }
}


#Preview {
    let library = SwiftDataLibraryRepository.preview()
    let shelves = (try? library.shelves()) ?? []
    let saved = try? library.item(for: PreviewCatalog.items[0].id)
    return VStack(spacing: 20) {
        ShelfMenu(kind: .book, shelves: shelves, current: nil, onSelect: { _ in }, onRemove: {})
        ShelfMenu(kind: .book, shelves: shelves, current: saved, onSelect: { _ in }, onRemove: {})
    }
}
