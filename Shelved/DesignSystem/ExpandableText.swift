import SwiftUI

/// Long text that starts collapsed with a "Show More" toggle.
///
/// Book descriptions and author bios can run to several screens. The toggle
/// only appears past a length threshold: measuring whether SwiftUI actually
/// truncated the text is possible but fiddly, and a rough cutoff is enough here.
struct ExpandableText: View {
    private let text: String
    private let collapsedLineLimit: Int
    @State private var isExpanded = false

    private static let toggleThreshold = 280

    init(_ text: String, collapsedLineLimit: Int = 6) {
        self.text = text
        self.collapsedLineLimit = collapsedLineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .lineLimit(isExpanded ? nil : collapsedLineLimit)

            if text.count > Self.toggleThreshold {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation { isExpanded.toggle() }
                }
                // Without this, tapping anywhere in the List row hits the button.
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    List {
        ExpandableText(String(repeating: "A desert planet, a noble family, a prophecy. ", count: 20))
        ExpandableText("Short text has no toggle.")
    }
}
