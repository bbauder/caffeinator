//
//  UpdateCheckerTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class UpdateCheckerTests: XCTestCase {

    final class StubFetcher: UpdateReleaseFetching {
        var nextResult: Result<UpdateRelease?, Error> = .success(nil)
        var callCount = 0

        func fetchLatestRelease() async throws -> UpdateRelease? {
            callCount += 1
            return try nextResult.get()
        }
    }

    var persistence: SettingsPersistenceManager!
    var fetcher: StubFetcher!

    override func setUp() async throws {
        try await super.setUp()
        let defaults = TestUserDefaults.make()
        persistence = SettingsPersistenceManager(defaults: defaults,
                                                 launchAtLoginResolver: { false })
        fetcher = StubFetcher()
    }

    // MARK: - Version comparison

    func test_isNewer_strictlyHigherMajor() {
        XCTAssertTrue(UpdateChecker.isNewerVersion("2.0", than: "1.9"))
    }

    func test_isNewer_strictlyHigherMinor() {
        XCTAssertTrue(UpdateChecker.isNewerVersion("1.2", than: "1.1"))
    }

    func test_isNewer_equalReturnsFalse() {
        XCTAssertFalse(UpdateChecker.isNewerVersion("1.1", than: "1.1"))
    }

    func test_isNewer_lowerReturnsFalse() {
        XCTAssertFalse(UpdateChecker.isNewerVersion("1.0", than: "1.1"))
    }

    func test_isNewer_stripsLeadingV() {
        XCTAssertTrue(UpdateChecker.isNewerVersion("v1.2", than: "1.1"))
        XCTAssertTrue(UpdateChecker.isNewerVersion("V1.2", than: "v1.1"))
    }

    func test_isNewer_numericCompareNotLexical() {
        // "1.10" must be greater than "1.2" — not less than as string compare would say.
        XCTAssertTrue(UpdateChecker.isNewerVersion("1.10", than: "1.2"))
    }

    func test_isNewer_ignoresPreReleaseSuffix() {
        // Pre-release suffix is ignored; the leading numeric portion wins.
        XCTAssertTrue(UpdateChecker.isNewerVersion("1.2-beta", than: "1.1"))
        XCTAssertFalse(UpdateChecker.isNewerVersion("1.1-beta", than: "1.1"))
    }

    func test_isNewer_padsMissingComponentsWithZero() {
        XCTAssertTrue(UpdateChecker.isNewerVersion("1.1.1", than: "1.1"))
        XCTAssertFalse(UpdateChecker.isNewerVersion("1.1", than: "1.1.0"))
    }

    // MARK: - Decision logic

    func test_checkNow_firesCallbackWhenNewerAvailable() async {
        let release = UpdateRelease(version: "1.2",
                                    releaseURL: URL(string: "https://example.com/r")!,
                                    releaseNotes: nil)
        fetcher.nextResult = .success(release)
        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)
        var fired: UpdateRelease?
        sut.onUpdateAvailable = { fired = $0 }

        await sut.checkNow()

        XCTAssertEqual(fired?.version, "1.2")
        XCTAssertNotNil(persistence.lastUpdateCheckDate)
        XCTAssertNotNil(sut.lastCheckedAt)
        XCTAssertEqual(sut.lastCheckOutcome, .updateFound(release))
    }

    func test_checkNow_doesNotFireWhenSameVersion() async {
        fetcher.nextResult = .success(UpdateRelease(version: "1.1",
                                                    releaseURL: URL(string: "https://example.com/r")!,
                                                    releaseNotes: nil))
        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)
        var fireCount = 0
        sut.onUpdateAvailable = { _ in fireCount += 1 }

        await sut.checkNow()

        XCTAssertEqual(fireCount, 0)
        XCTAssertEqual(sut.lastCheckOutcome, .upToDate)
    }

    func test_checkNow_doesNotFireWhenVersionSkipped() async {
        persistence.skippedUpdateVersion = "1.2"
        fetcher.nextResult = .success(UpdateRelease(version: "1.2",
                                                    releaseURL: URL(string: "https://example.com/r")!,
                                                    releaseNotes: nil))
        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)
        var fireCount = 0
        sut.onUpdateAvailable = { _ in fireCount += 1 }

        await sut.checkNow()

        XCTAssertEqual(fireCount, 0)
        XCTAssertEqual(sut.lastCheckOutcome, .upToDate,
                       "Skipped version should look like up-to-date to the UI")
    }

    func test_checkNow_force_bypassesSkippedVersion() async {
        persistence.skippedUpdateVersion = "1.2"
        let release = UpdateRelease(version: "1.2",
                                    releaseURL: URL(string: "https://example.com/r")!,
                                    releaseNotes: nil)
        fetcher.nextResult = .success(release)
        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)
        var fired: UpdateRelease?
        sut.onUpdateAvailable = { fired = $0 }

        await sut.checkNow(force: true)

        XCTAssertEqual(fired?.version, "1.2",
                       "Manual Check Now must surface a previously-skipped version")
        XCTAssertEqual(sut.lastCheckOutcome, .updateFound(release))
    }

    func test_checkNow_swallowsFetchErrors() async {
        struct Boom: Error {}
        fetcher.nextResult = .failure(Boom())
        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)
        var fireCount = 0
        sut.onUpdateAvailable = { _ in fireCount += 1 }

        await sut.checkNow()

        XCTAssertEqual(fireCount, 0)
        XCTAssertNil(persistence.lastUpdateCheckDate,
                     "Failed fetch must not advance the last-check timestamp")
        XCTAssertNil(sut.lastCheckedAt,
                     "Failed fetch must not advance the published lastCheckedAt")
        XCTAssertEqual(sut.lastCheckOutcome, .failed)
    }

    func test_init_seedsLastCheckedAtFromPersistence() {
        let stored = Date(timeIntervalSince1970: 1_700_000_000)
        persistence.lastUpdateCheckDate = stored

        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)

        XCTAssertEqual(sut.lastCheckedAt, stored)
    }

    // MARK: - Due gating

    func test_checkIfDue_skipsFetchWhenCheckedRecently() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        persistence.lastUpdateCheckDate = now.addingTimeInterval(-60 * 60)  // 1h ago

        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher,
                                checkInterval: 24 * 60 * 60,
                                dateProvider: { now })

        await sut.checkIfDue()

        XCTAssertEqual(fetcher.callCount, 0)
    }

    func test_checkIfDue_runsFetchWhenStale() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        persistence.lastUpdateCheckDate = now.addingTimeInterval(-2 * 24 * 60 * 60)  // 2d ago

        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher,
                                checkInterval: 24 * 60 * 60,
                                dateProvider: { now })

        await sut.checkIfDue()

        XCTAssertEqual(fetcher.callCount, 1)
    }

    func test_checkIfDue_runsFetchOnFirstEverCheck() async {
        XCTAssertNil(persistence.lastUpdateCheckDate)
        let sut = UpdateChecker(currentVersion: "1.1",
                                persistence: persistence,
                                fetcher: fetcher)

        await sut.checkIfDue()

        XCTAssertEqual(fetcher.callCount, 1)
    }
}
