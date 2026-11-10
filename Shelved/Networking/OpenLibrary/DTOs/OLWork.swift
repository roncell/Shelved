import Foundation

/// The raw JSON from /works/{id}.json.
nonisolated struct OLWork: Decodable, Sendable {
    let key: String
    let title: String?
    let description: OLText?
    let covers: [Int]?              // can contain -1 for "no cover"
    let authors: [OLWorkAuthor]?
    let subjects: [String]?
    let firstPublishDate: String?   // free text: "1965", "August 1965"…

    nonisolated enum CodingKeys: String, CodingKey {
        case key, title, description, covers, authors, subjects
        case firstPublishDate = "first_publish_date"
    }
}
