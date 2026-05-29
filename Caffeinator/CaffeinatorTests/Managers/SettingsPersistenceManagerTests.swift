//
//  SettingsPersistenceManagerTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class SettingsPersistenceManagerTests: XCTestCase {

    var defaults: UserDefaults!
    var sut: SettingsPersistenceManager!

    override func setUp() async throws {
        try await super.setUp()
        defaults = TestUserDefaults.make()
        sut = SettingsPersistenceManager(defaults: defaults,
                                         launchAtLoginResolver: { false })
    }

    // MARK: - Defaults

    func test_registeredDefaultsApply() {
        XCTAssertTrue(sut.preventSystemSleep)
        XCTAssertFalse(sut.preventDisplaySleep)
        XCTAssertFalse(sut.preventScreenSaver)
        XCTAssertTrue(sut.hideActivationOptionsWhileActive)
        XCTAssertTrue(sut.showRecentDurations)
        XCTAssertTrue(sut.showStatusText)
        XCTAssertTrue(sut.animateIcon)
        XCTAssertFalse(sut.declareUserActivity)
        XCTAssertFalse(sut.autoDisableOnLowBattery)
        XCTAssertEqual(sut.lowBatteryThreshold, 20)
        XCTAssertFalse(sut.autoDisableOnUnpluggedPower)
        XCTAssertFalse(sut.autoDisableNotificationsEnabled)
        XCTAssertFalse(sut.notifyOnTimerExpired)
        XCTAssertFalse(sut.notifyOnWatchedAppsFinished)
        XCTAssertEqual(sut.mruEntries, [])
    }

    func test_allNotificationSettingsDefaultToOff() {
        XCTAssertFalse(sut.autoDisableNotificationsEnabled)
        XCTAssertFalse(sut.notifyOnTimerExpired)
        XCTAssertFalse(sut.notifyOnWatchedAppsFinished)
    }

    func test_launchAtLoginUsesResolver() {
        let other = SettingsPersistenceManager(defaults: TestUserDefaults.make(),
                                               launchAtLoginResolver: { true })
        XCTAssertTrue(other.launchAtLogin)
    }

    // MARK: - Setter persistence

    func test_setPreventSystemSleep_persists() {
        sut.preventSystemSleep = false
        XCTAssertFalse(defaults.bool(forKey: "preventSystemSleep"))
    }

    func test_setLowBatteryThreshold_persists() {
        sut.lowBatteryThreshold = 42
        XCTAssertEqual(defaults.integer(forKey: "lowBatteryThreshold"), 42)
    }

    func test_setShowStatusText_persists() {
        sut.showStatusText = false
        XCTAssertFalse(defaults.bool(forKey: "showStatusText"))
    }

    func test_setNotifyOnTimerExpired_persists() {
        sut.notifyOnTimerExpired = true
        XCTAssertTrue(defaults.bool(forKey: "notifyOnTimerExpired"))
    }

    func test_setNotifyOnWatchedAppsFinished_persists() {
        sut.notifyOnWatchedAppsFinished = true
        XCTAssertTrue(defaults.bool(forKey: "notifyOnWatchedAppsFinished"))
    }

    // MARK: - MRU JSON round-trip

    func test_mruEntries_jsonRoundTrip() {
        let entries: [MRUEntry] = [.indefinitely,
                                   .duration(900),
                                   .untilTime(hour: 22, minute: 0)]
        sut.mruEntries = entries

        let reloaded = SettingsPersistenceManager(defaults: defaults,
                                                  launchAtLoginResolver: { false })
        XCTAssertEqual(reloaded.mruEntries, entries)
    }

    func test_mruEntries_emptyWhenAbsent() {
        XCTAssertEqual(sut.mruEntries, [])
    }
}
