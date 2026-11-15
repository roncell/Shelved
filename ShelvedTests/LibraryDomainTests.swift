import Foundation
import Testing
@testable import Core
@testable import Data

/// Pure value types: no store, no network, no main actor.
struct RatingTests {
    @Test(arguments: [
        (3.5, 7),
        (3.3, 7),    // rounds to the nearest half
        (3.2, 6),
        (0.5, 1),
        (5.0, 10),
    ] as [(Double, Int)])
    func roundsToHalfStars(stars: Double, expected: Int) {
        #expect(Rating(stars: stars)?.halfStars == expected)
    }

    @Test(arguments: [0.0, 0.2, 5.5, -1.0])
    func rejectsOutOfRange(stars: Double) {
        #expect(Rating(stars: stars) == nil)
    }
}

struct StorageKeyTests {
    @Test func mediaIDRoundTrips() {
        let id = MediaID.openLibraryWork("OL893414W")
        #expect(id.storageKey == "openlibrary:work:OL893414W")
        #expect(MediaID(storageKey: id.storageKey) == id)
    }

    @Test func creatorIDRoundTrips() {
        let id = CreatorID.openLibraryAuthor("OL79034A")
        #expect(CreatorID(storageKey: id.storageKey) == id)
    }

    /// Keys written by a future version (or corrupted) must not crash or
    /// turn into the wrong ID.
    @Test(arguments: [MediaID.tmdbFilm(550), .tmdbShow(1399), .openLibraryWork("OL1W")])
    func everyMediaIDRoundTrips(id: MediaID) {
        #expect(MediaID(storageKey: id.storageKey) == id)
    }

    @Test func tmdbKeysAreReadable() {
        #expect(MediaID.tmdbFilm(550).storageKey == "tmdb:film:550")
        #expect(CreatorID(storageKey: "tmdb:person:287") == .tmdbPerson(287))
    }

    @Test(arguments: ["", "OL893414W", "openlibrary:work:", "tmdb:film:abc", "tmdb:movie:550", "openlibrary:author:OL1A"])
    func rejectsUnknownMediaKeys(key: String) {
        #expect(MediaID(storageKey: key) == nil)
    }
}

struct ReadingLogTests {
    private let monday = Date(timeIntervalSince1970: 1_700_000_000)
    private let friday = Date(timeIntervalSince1970: 1_700_345_600)

    @Test func startingSetsStartDate() {
        let log = ReadingLog().movedTo(.inProgress, at: monday)
        #expect(log.startedAt == monday)
        #expect(log.finishedAt == nil)
    }

    @Test func finishingKeepsExistingDates() {
        let started = ReadingLog(startedAt: monday)
        let finished = started.movedTo(.finished, at: friday)
        #expect(finished.startedAt == monday)
        #expect(finished.finishedAt == friday)

        // Moving to Finished again doesn't overwrite the user's date.
        #expect(finished.movedTo(.finished, at: .now).finishedAt == friday)
    }

    @Test func otherShelvesLeaveDatesAlone() {
        #expect(ReadingLog().movedTo(.wantTo, at: monday) == ReadingLog())
        #expect(ReadingLog().movedTo(nil, at: monday) == ReadingLog())
    }

    @Test func validation() {
        #expect(ReadingLog(progress: 50, progressTotal: 100).validationErrors.isEmpty)
        #expect(ReadingLog(progress: 150, progressTotal: 100).validationErrors.count == 1)
        #expect(ReadingLog(startedAt: friday, finishedAt: monday).validationErrors.count == 1)
    }
}
