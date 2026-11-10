import Foundation

/// The raw JSON from /works/{id}.json.
nonisolated struct OLWork: Decodable, Sendable, OLRedirectable {
    let key: String
    let title: String?
    let description: OLText?
    let covers: [Int]?              // can contain -1 for "no cover"
    let authors: [OLWorkAuthor]?
    let subjects: [String]?
    let subjectPlaces: [String]?
    let subjectPeople: [String]?
    let subjectTimes: [String]?
    let links: [OLLink]?
    let firstPublishDate: String?   // free text: "1965", "August 1965"…
    let type: OLKeyRef?
    let location: String?           // set only on redirect records

    nonisolated enum CodingKeys: String, CodingKey {
        case key, title, description, covers, authors, subjects, links, type, location
        case subjectPlaces = "subject_places"
        case subjectPeople = "subject_people"
        case subjectTimes = "subject_times"
        case firstPublishDate = "first_publish_date"
    }
}
