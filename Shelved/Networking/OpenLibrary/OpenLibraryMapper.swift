import Foundation

/// Converts Open Library DTOs into domain models.
///
/// Pure functions with no networking, so they're trivial to unit test.
/// This is the *only* place that knows both shapes.
nonisolated enum OpenLibraryMapper {
    nonisolated enum CoverSize: String {
        case small = "S", medium = "M", large = "L"
    }

    /// Long subject lists ("Fiction", "Science fiction", "Fiction, general"…)
    /// add noise, not information.
    private static let maxSubjects = 10

    /// Returns nil for records we can't display (no title, bad key),
    /// so callers can use `compactMap`.
    static func item(from doc: OLSearchDoc) -> MediaItem? {
        guard let title = doc.title, let workID = id(fromKey: doc.key) else { return nil }

        // author_key and author_name are parallel arrays; zip pairs them up.
        let creators = zip(doc.authorKey ?? [], doc.authorName ?? []).map { key, name in
            CreatorSummary(id: .openLibraryAuthor(key), name: name)
        }

        return MediaItem(
            id: .openLibraryWork(workID),
            kind: .book,
            title: title,
            creators: creators,
            coverURL: doc.coverI.flatMap { coverURL(coverID: $0, size: .medium) },
            year: doc.firstPublishYear
        )
    }

    static func detail(from work: OLWork, id: MediaID, creators: [CreatorSummary]) -> MediaDetail {
        let coverID = work.covers?.first { $0 > 0 }
        return MediaDetail(
            id: id,
            kind: .book,
            title: work.title ?? String(localized: "Untitled"),
            creators: creators,
            coverURL: coverID.flatMap { coverURL(coverID: $0, size: .large) },
            year: year(from: work.firstPublishDate),
            summary: work.description?.value,
            subjects: Array((work.subjects ?? []).prefix(maxSubjects)),
            places: Array((work.subjectPlaces ?? []).prefix(maxSubjects)),
            characters: Array((work.subjectPeople ?? []).prefix(maxSubjects)),
            timePeriods: Array((work.subjectTimes ?? []).prefix(maxSubjects)),
            links: (work.links ?? []).compactMap(link(from:))
        )
    }

    static func creator(from author: OLAuthor, authorID: String) -> CreatorSummary? {
        guard let name = author.name ?? author.personalName else { return nil }
        return CreatorSummary(id: .openLibraryAuthor(authorID), name: name)
    }

    /// Unlike `creator(from:)`, this never returns nil: the user tapped this
    /// author, so show *something* even if the record has no name.
    static func creatorDetail(from author: OLAuthor, authorID: String) -> CreatorDetail {
        let photoID = author.photos?.first { $0 > 0 }
        return CreatorDetail(
            id: .openLibraryAuthor(authorID),
            name: author.name ?? author.personalName ?? String(localized: "Unknown Author"),
            bio: author.bio?.value,
            birthDate: author.birthDate,
            deathDate: author.deathDate,
            photoURL: photoID.flatMap { authorPhotoURL(photoID: $0, size: .large) }
        )
    }

    /// Drops links with no title or an unparseable URL. Crowd-sourced data
    /// has both, and a link the user can't read or open is worse than none.
    static func link(from dto: OLLink) -> MediaLink? {
        guard let title = dto.title, !title.isEmpty,
              let string = dto.url, let url = URL(string: string), url.scheme != nil
        else { return nil }
        return MediaLink(title: title, url: url)
    }

    /// "/works/OL893415W" → "OL893415W"
    static func id(fromKey key: String) -> String? {
        guard let last = key.split(separator: "/").last, !last.isEmpty else { return nil }
        return String(last)
    }

    /// https://covers.openlibrary.org/b/id/{id}-{S|M|L}.jpg
    static func coverURL(coverID: Int, size: CoverSize) -> URL? {
        guard coverID > 0 else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-\(size.rawValue).jpg")
    }

    /// Author photos live under /a/ instead of /b/:
    /// https://covers.openlibrary.org/a/id/{id}-{S|M|L}.jpg
    static func authorPhotoURL(photoID: Int, size: CoverSize) -> URL? {
        guard photoID > 0 else { return nil }
        return URL(string: "https://covers.openlibrary.org/a/id/\(photoID)-\(size.rawValue).jpg")
    }

    /// Pulls the first 4-digit year out of free text like "August 1965".
    static func year(from text: String?) -> Int? {
        guard let text, let match = text.firstMatch(of: /\d{4}/) else { return nil }
        return Int(match.output)
    }
}
