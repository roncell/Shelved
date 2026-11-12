import SwiftUI

/// Tap or drag across the stars to rate, in half-star steps.
///
/// The left half of a star gives a half star, the right half a full one.
/// VoiceOver users swipe up/down instead (the adjustable action), since
/// "tap the left half of the third star" isn't something they can aim for.
struct RatingPicker: View {
    @Binding var rating: Rating?

    /// Scales with Dynamic Type, so the stars grow with the user's text size.
    @ScaledMetric(relativeTo: .title) private var starSize: CGFloat = 32
    private let spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: RatingView.symbol(forStar: star, halfStars: rating?.halfStars ?? 0))
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
            }
        }
        .foregroundStyle(.orange)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    rating = Rating(halfStars: halfStars(atX: value.location.x))
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rating"))
        .accessibilityValue(RatingView.accessibilityText(for: rating))
        .accessibilityAdjustableAction { direction in
            let current = rating?.halfStars ?? 0
            switch direction {
            case .increment: rating = Rating(halfStars: min(current + 1, Rating.maxHalfStars)) ?? rating
            case .decrement: rating = Rating(halfStars: current - 1)
            @unknown default: break
            }
        }
    }

    /// Which half star a touch at `x` lands on, from 1 to 10.
    private func halfStars(atX x: CGFloat) -> Int {
        let starPitch = starSize + spacing
        let halves = Int((x / starPitch * 2).rounded(.up))
        return min(max(halves, 1), Rating.maxHalfStars)
    }
}

#Preview {
    @Previewable @State var rating = Rating(stars: 3.5)
    VStack {
        RatingPicker(rating: $rating)
        Text(rating.map { "\($0.stars)" } ?? "none")
    }
}
