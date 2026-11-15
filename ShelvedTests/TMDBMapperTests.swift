import Foundation
import Testing
@testable import Core
@testable import Data
@testable import Networking

private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(json.utf8))
}

struct TMDBMapperTests {
    @Test func filmDetailUsesDirectorsCastOrderAndLinks() throws {
        let movie = try decode(TMDBMovie.self, """
            {"id": 329865, "title": "Arrival", "release_date": "2016-11-10", "runtime": 116,
             "overview": "A linguist…", "poster_path": "/x.jpg", "imdb_id": "tt2543164", "homepage": "",
             "genres": [{"id": 18, "name": "Drama"}],
             "credits": {
               "cast": [{"id": 2, "name": "Jeremy Renner", "character": "Ian", "order": 1},
                        {"id": 1, "name": "Amy Adams", "character": "Louise", "order": 0}],
               "crew": [{"id": 9, "name": "Denis Villeneuve", "job": "Director"},
                        {"id": 8, "name": "Jóhann Jóhannsson", "job": "Original Music Composer"}]}}
            """)

        let detail = TMDBMapper.detail(from: movie)

        #expect(detail.id == .tmdbFilm(329865))
        #expect(detail.kind == .film)
        #expect(detail.year == 2016)
        #expect(detail.creators.map(\.name) == ["Denis Villeneuve"])
        #expect(detail.cast.map(\.person.name) == ["Amy Adams", "Jeremy Renner"])   // billing order
        #expect(detail.subjects == ["Drama"])
        #expect(detail.runtimeMinutes == 116)
        #expect(detail.links.map(\.title) == ["IMDb"])   // empty homepage dropped
        #expect(detail.coverURL?.absoluteString == "https://image.tmdb.org/t/p/w342/x.jpg")
    }

    @Test func showDetailUsesCreatorsAndCounts() throws {
        let show = try decode(TMDBShow.self, """
            {"id": 95396, "name": "Severance", "first_air_date": "2022-02-17",
             "number_of_seasons": 2, "number_of_episodes": 19,
             "created_by": [{"id": 5, "name": "Dan Erickson"}]}
            """)

        let detail = TMDBMapper.detail(from: show)

        #expect(detail.id == .tmdbShow(95396))
        #expect(detail.creators.map(\.id) == [.tmdbPerson(5)])
        #expect(detail.seasonCount == 2)
        #expect(detail.episodeCount == 19)
        #expect(detail.cast.isEmpty)   // no credits block: empty, not a crash
    }

    @Test func multiSearchDropsPeopleAndUntitledRows() throws {
        let page = try decode(TMDBPage<TMDBListItem>.self, """
            {"page": 1, "total_pages": 3, "results": [
              {"id": 1, "media_type": "movie", "title": "Arrival", "release_date": "2016-11-10"},
              {"id": 2, "media_type": "person", "name": "Amy Adams"},
              {"id": 3, "media_type": "tv", "name": "Severance", "first_air_date": ""},
              {"id": 4, "media_type": "movie", "title": "  "}]}
            """)

        let result = TMDBMapper.page(from: page, defaultKind: nil)

        #expect(result.items.map(\.id) == [.tmdbFilm(1), .tmdbShow(3)])
        #expect(result.items.last?.year == nil)   // "" date
        #expect(result.hasMore)
    }

    /// /search/movie rows have no media_type; the endpoint says what they are.
    @Test func singleKindSearchUsesDefaultKind() throws {
        let page = try decode(TMDBPage<TMDBListItem>.self, """
            {"page": 1, "total_pages": 1, "results": [{"id": 7, "title": "Arrival"}]}
            """)

        let result = TMDBMapper.page(from: page, defaultKind: .film)

        #expect(result.items.map(\.id) == [.tmdbFilm(7)])
        #expect(!result.hasMore)
    }

    @Test func worksDropTalkShowsAndDuplicatesAndSortByPopularity() throws {
        let credits = try decode(TMDBCombinedCredits.self, """
            {"cast": [
               {"id": 1, "media_type": "movie", "title": "Small Film", "popularity": 2},
               {"id": 2, "media_type": "tv", "name": "Late Show", "popularity": 90, "genre_ids": [10767]},
               {"id": 3, "media_type": "movie", "title": "Big Film", "popularity": 50}],
             "crew": [
               {"id": 3, "media_type": "movie", "title": "Big Film", "popularity": 50}]}
            """)

        let works = TMDBMapper.works(from: credits)

        #expect(works.map(\.title) == ["Big Film", "Small Film"])
    }

    @Test func personDatesAndEmptyBio() throws {
        let person = try decode(TMDBPerson.self, """
            {"id": 137427, "name": "Denis Villeneuve", "biography": "", "birthday": "1967-10-03", "deathday": null}
            """)

        let creator = TMDBMapper.creatorDetail(from: person)

        #expect(creator.bio == nil)
        #expect(creator.deathDate == nil)
        // Formatted in UTC, so the day never slips to the 2nd in western time zones.
        let birth = try #require(creator.birthDate)
        #expect(birth.contains("1967") && birth.contains("3"))
        #expect(!birth.contains("2,"))
    }
}
