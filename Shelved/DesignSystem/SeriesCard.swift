import SwiftUI

/// "Series · A Song of Ice and Fire · 7 books", shown above search results
/// when the top book belongs to a series.
struct SeriesCard: View {
    let membership: SeriesMembership
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "books.vertical")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Series")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(membership.seriesName)
                        .font(.headline)
                    Text("^[\(membership.entryCount) book](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(.primary)
        // VoiceOver: "Series, Dune, 3 books".
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Shows every book in the series"))
    }
}

#Preview {
    List {
        SeriesCard(membership: SeriesMembership(
            seriesID: .wikidata("Q45875"), seriesName: "A Song of Ice and Fire",
            position: "1", total: 7, entryCount: 7
        )) {}
    }
}
