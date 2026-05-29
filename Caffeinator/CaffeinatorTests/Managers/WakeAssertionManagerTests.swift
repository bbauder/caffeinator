//
//  WakeAssertionManagerTests.swift
//  CaffeinatorTests
//

import XCTest
import IOKit.pwr_mgt
@testable import Caffeinator

@MainActor
final class WakeAssertionManagerTests: XCTestCase {

    var assertions: FakePowerAssertionProvider!
    var persistence: SettingsPersistenceManager!
    var mruStore: MRUStore!
    var settings: SettingsViewModel!
    var sut: WakeAssertionManager!

    override func setUp() async throws {
        try await super.setUp()
        assertions = FakePowerAssertionProvider()
        persistence = SettingsPersistenceManager(defaults: TestUserDefaults.make(),
                                                 launchAtLoginResolver: { false })
        mruStore = MRUStore(persistence: persistence)
        settings = SettingsViewModel(persistence: persistence,
                                     mruStore: mruStore,
                                     notificationManager: NotificationManager(delivery: FakeNotificationDelivery()),
                                     batteryMonitor: BatteryMonitor(batteryLevelProvider: { nil }),
                                     powerSourceMonitor: PowerSourceMonitor(powerStateProvider: { true }),
                                     userActivityManager: UserActivityManager(declareActivity: { _ in }),
                                     launchAtLoginUpdater: { $0 })

        sut = WakeAssertionManager(assertions: assertions,
                                   tickInterval: .milliseconds(5))
        sut.settings = settings
        settings.wakeManager = sut
    }

    override func tearDown() async throws {
        sut.deactivate()
        try await super.tearDown()
    }

    // MARK: - Activation paths

    func test_activateIndefinitely_setsState() {
        sut.activateIndefinitely()
        XCTAssertTrue(sut.isActive)
        XCTAssertNil(sut.timeRemaining)
        XCTAssertNil(sut.selectedDuration)
        XCTAssertNil(sut.selectedStopTime)
    }

    func test_activateIndefinitely_recordsMRU() {
        sut.activateIndefinitely()
        XCTAssertEqual(mruStore.entries.first, .indefinitely)
    }

    func test_activateForProcessWatch_setsActiveWithoutMRU() {
        sut.activateForProcessWatch()
        XCTAssertTrue(sut.isActive)
        XCTAssertTrue(mruStore.entries.isEmpty)
    }

    func test_activateForDuration_setsTimeAndMRU() {
        sut.activate(for: 60)
        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.timeRemaining, 60)
        XCTAssertEqual(sut.selectedDuration, 60)
        XCTAssertEqual(mruStore.entries.first, .duration(60))
    }

    func test_activateUntilFuture_setsStopTimeAndMRU() {
        let future = Date.now.addingTimeInterval(3600)
        sut.activate(until: future)

        XCTAssertTrue(sut.isActive)
        XCTAssertNotNil(sut.selectedStopTime)
        let components = Calendar.current.dateComponents([.hour, .minute], from: future)
        XCTAssertEqual(mruStore.entries.first, .untilTime(hour: components.hour!, minute: components.minute!))
    }

    func test_activateUntilPast_wrapsToNextDay() {
        let past = Date.now.addingTimeInterval(-3600)
        sut.activate(until: past)

        XCTAssertTrue(sut.isActive)
        guard let stop = sut.selectedStopTime else {
            return XCTFail("expected stopTime")
        }
        XCTAssertGreaterThan(stop, Date.now)
    }

    // MARK: - Assertion creation

    func test_activate_alwaysCreatesBothAssertions() {
        sut.activateIndefinitely()

        XCTAssertEqual(assertions.createCount, 2)
        XCTAssertEqual(assertions.liveCount, 2)
        XCTAssertEqual(assertions.createCount(forType: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString), 1)
        XCTAssertEqual(assertions.createCount(forType: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString), 1)
    }

    func test_deactivate_releasesAllAssertions() {
        sut.activateIndefinitely()
        XCTAssertEqual(assertions.liveCount, 2)

        sut.deactivate()
        XCTAssertEqual(assertions.liveCount, 0)
        XCTAssertFalse(sut.isActive)
    }

    func test_reactivate_replacesAssertionsCleanly() {
        sut.activateIndefinitely()
        sut.activate(for: 60)

        XCTAssertEqual(assertions.liveCount, 2)
    }

    // MARK: - fillLevel

    func test_fillLevel_inactive_isZero() {
        XCTAssertEqual(sut.fillLevel, 0)
    }

    func test_fillLevel_indefinite_isOne() {
        sut.activateIndefinitely()
        XCTAssertEqual(sut.fillLevel, 1.0)
    }

    func test_fillLevel_timed_isRemainingOverTotal() {
        sut.activate(for: 100)
        XCTAssertEqual(sut.fillLevel, 1.0, accuracy: 0.01)
    }

    // MARK: - Countdown

    func test_countdown_firesOnTimerExpired() async {
        let expectation = expectation(description: "timer expired")
        sut.onTimerExpired = { expectation.fulfill() }
        sut.activate(for: 1)

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(sut.isActive)
    }

    func test_deactivate_cancelsCountdown() async {
        var fired = false
        sut.onTimerExpired = { fired = true }
        sut.activate(for: 5)
        sut.deactivate()

        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(fired)
    }
}
