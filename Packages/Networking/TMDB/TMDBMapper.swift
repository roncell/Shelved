import Core
import Data
import Foundation

/// Converts TMDB DTOs into domain models. Pure functions, like `OpenLibraryMapper`.
nonisolated enum TMDBMapper {
    static let maxCast = 15
    /// Talk shows and news: an actor's appearances on these are interviews,
    /// not work, and they'd crowd the top of a popularity-sorted list.
    private static let appearanceGenres: Set<Int> = [10767, 10763]

    /// nil for people and for rows we can't show.
    ///
    /// - Parameter defaultKind: for single-kind searches, whose rows have no
    ///   `media_type`.
    static func item(from dto: TMDBListItem, defaultKind: MediaKind? = nil) -> MediaItem? {
        let kind: MediaKind
        switch dto.mediaType {
        case "movie": kind = .film
        case "tv": kind = .show
        case nil:
            guard let defaultKind, defaultKind != .book else { return nil }
            kind = defaultKind
        default:
            return nil   // "person"
        }
        guard let title = nonEmpty(dto.title ?? dto.name) else { return nil }

        return MediaItem(
            id: kind == .film ? .tmdbFilm(dto.id) : .tmdbShow(dto.id),
            kind: kind,
            title: title,
            creators: [],   // search results don't include directors
            coverURL: TMDBAPI.imageURL(path: dto.posterPath, size: .poster),
            year: year(from: dto.releaseDate ?? dto.firstAirDate)
        )
    }

    static func page(from response: TMDBPage<TMDBListItem>, defaultKind: MediaKind?) -> SearchPage {
        SearchPage(
            items: response.results.compactMap { item(from: $0, defaultKind: defaultKind) },
            hasMore: response.page < response.totalPages
        )
    }

    static func detail(from movie: TMDBMovie) -> MediaDetail {
        let directors = (movie.credits?.crew ?? [])
            .filter { $0.job == "Director" }
            .map { CreatorSummary(id: .tmdbPerson($0.id), name: $0.name) }

        var links: [MediaLink] = []
        if let homepage = nonEmpty(movie.homepage).flatMap(URL.init(string:)) {
            links.append(MediaLink(title: String(localized: "Official Site"), url: homepage))
        }
        if let imdbID = nonEmpty(movie.imdbID), let imdb = URL(string: "https://www.imdb.com/title/\(imdbID)/") {
            links.append(MediaLink(title: "IMDb", url: imdb))
        }

        return MediaDetail(
            id: .tmdbFilm(movie.id),
            kind: .film,
            title: nonEmpty(movie.title) ?? String(localized: "Untitled"),
            creators: unique(directors),
            coverURL: TMDBAPI.imageURL(path: movie.posterPath, size: .poster),
            year: year(from: movie.releaseDate),
            summary: nonEmpty(movie.overview),
            subjects: (movie.genres ?? []).map(\.name),
            places: [], characters: [], timePeriods: [],
            links: links,
            cast: cast(from: movie.credits),
            runtimeMinutes: movie.runtime.flatMap { $0 > 0 ? $0 : nil }
        )
    }

    static func detail(from show: TMDBShow) -> MediaDetail {
        var links: [MediaLink] = []
        if let homepage = nonEmpty(show.homepage).flatMap(URL.init(string:)) {
            links.append(MediaLink(title: String(localized: "Official Site"), url: homepage))
        }

        return MediaDetail(
            id: .tmdbShow(show.id),
            kind: .show,
            title: nonEmpty(show.name) ?? String(localized: "Untitled"),
            creators: unique((show.createdBy ?? []).map { CreatorSummary(id: .tmdbPerson($0.id), name: $0.name) }),
            coverURL: TMDBAPI.imageURL(path: show.posterPath, size: .poster),
            year: year(from: show.firstAirDate),
            summary: nonEmpty(show.overview),
            subjects: (show.genres ?? []).map(\.name),
            places: [], characters: [], timePeriods: [],
            links: links,
            cast: cast(from: show.credits),
            seasonCount: show.numberOfSeasons,
            episodeCount: show.numberOfEpisodes
        )
    }

    static func creatorDetail(from person: TMDBPerson) -> CreatorDetail {
        CreatorDetail(
            id: .tmdbPerson(person.id),
            name: nonEmpty(person.name) ?? String(localized: "Unknown"),
            bio: nonEmpty(person.biography),
            birthDate: displayDate(person.birthday),
            deathDate: displayDate(person.deathday),
            photoURL: TMDBAPI.imageURL(path: person.profilePath, size: .profile)
        )
    }

    /// Acting and crew credits together, most popular first, each title once
    /// (a director who also cameos appears in both lists).
    static func works(from credits: TMDBCombinedCredits) -> [MediaItem] {
        var seen = Set<MediaID>()
        return ((credits.cast ?? []) + (credits.crew ?? []))
            .filter { appearanceGenres.isDisjoint(with: $0.genreIDs ?? []) }
            .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
            .compactMap { item(from: $0) }
            .filter { seen.insert($0.id).inserted }
    }

    /// "2016-11-10" → 2016. TMDB sends "" for unknown dates.
    static func year(from date: String?) -> Int? {
        guard let date, date.count >= 4 else { return nil }
        return Int(date.prefix(4))
    }

    /// "1967-10-03" → "October 3, 1967" in the user's locale. Formatted in
    /// UTC because the parsed date is UTC midnight; local time would show
    /// the day before for anyone west of Greenwich.
    static func displayDate(_ iso: String?) -> String? {
        guard let iso = nonEmpty(iso) else { return nil }
        guard let date = try? Date(iso, strategy: Date.ISO8601FormatStyle().year().month().day()) else {
            return iso
        }
        var style = Date.FormatStyle(date: .long, time: .omitted)
        style.timeZone = .gmt
        return date.formatted(style)
    }

    private static func cast(from credits: TMDBCredits?) -> [CastCredit] {
        var seen = Set<Int>()
        return (credits?.cast ?? [])
            .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
            .filter { seen.insert($0.id).inserted }
            .prefix(maxCast)
            .map { CastCredit(person: CreatorSummary(id: .tmdbPerson($0.id), name: $0.name), character: nonEmpty($0.character)) }
    }

    private static func unique(_ creators: [CreatorSummary]) -> [CreatorSummary] {
        var seen = Set<CreatorID>()
        return creators.filter { seen.insert($0.id).inserted }
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
