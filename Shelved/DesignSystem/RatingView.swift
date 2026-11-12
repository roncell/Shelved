import SwiftUI

/// Read-only stars, e.g. "★★★½☆" in a list row.
struct RatingView: View {
    let rating: Rating?
    var size: Font = .caption

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Self.symbol(forStar: star, halfStars: rating?.halfStars ?? 0))
            }
        }
        .font(size)
        .foregroundStyle(.orange)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityText(for: rating))
    }

    /// Star 3 with 5 half-stars (2.5) → half filled.
    static func symbol(forStar star: Int, halfStars: Int) -> String {
        let filledHalves = halfStars - (star - 1) * 2
        switch filledHalves {
        case 2...: return "star.fill"
        case 1: return "star.leadinghalf.filled"
        default: return "star"
        }
    }

    static func accessibilityText(for rating: Rating?) -> Text {
        guard let rating else { return Text("Not rated") }
        return Text("\(rating.stars.formatted()) out of 5 stars")
    }
}

#Preview {
    VStack(alignment: .leading) {
        RatingView(rating: Rating(stars: 3.5))
        RatingView(rating: Rating(stars: 5), size: .title)
        RatingView(rating: nil)
    }
}
