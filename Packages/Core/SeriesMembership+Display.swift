import Foundation

extension SeriesMembership {
    /// "Book 2 of 5 · Dune", or "Book 2 · Dune" when the total can't be trusted.
    public var positionText: String {
        if let total {
            String(localized: "Book \(position) of \(total) · \(seriesName)")
        } else {
            String(localized: "Book \(position) · \(seriesName)")
        }
    }
}
