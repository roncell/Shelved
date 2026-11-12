import Foundation

/// 0.5 to 5 stars, in half-star steps.
///
/// Stored as a whole number of half stars (1–10) instead of a Double, so
/// "is this 3.5?" is exact integer equality, never floating-point rounding.
/// The failable inits make an out-of-range rating impossible to construct.
nonisolated struct Rating: Hashable, Sendable {
    static let maxHalfStars = 10

    let halfStars: Int

    init?(halfStars: Int) {
        guard (1...Self.maxHalfStars).contains(halfStars) else { return nil }
        self.halfStars = halfStars
    }

    /// Rounds to the nearest half star: 3.3 → 3.5, 3.2 → 3.0.
    init?(stars: Double) {
        self.init(halfStars: Int((stars * 2).rounded()))
    }

    var stars: Double { Double(halfStars) / 2 }
}
