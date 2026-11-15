import Core
import SwiftUI

/// The last row of a paged list. When it scrolls into view, the next page loads.
///
/// Shared by Search and the creator screen. It lives in DesignSystem, not in
/// either feature, because features can't import each other.
package struct LoadMoreFooter: View {
    /// Changes whenever a page arrives (pass the item count). After a page
    /// loads this row is often still on screen, so the task must re-fire.
    package let trigger: Int
    package let failed: Bool
    package let loadMore: @MainActor () async -> Void

    package init(trigger: Int, failed: Bool, loadMore: @escaping @MainActor () async -> Void) {
        self.trigger = trigger
        self.failed = failed
        self.loadMore = loadMore
    }

    package var body: some View {
        HStack {
            Spacer()
            if failed {
                Button("Load More") {
                    Task { await loadMore() }
                }
            } else {
                ProgressView()
                    .task(id: trigger) { await loadMore() }
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    List {
        LoadMoreFooter(trigger: 0, failed: false) {}
        LoadMoreFooter(trigger: 0, failed: true) {}
    }
}
