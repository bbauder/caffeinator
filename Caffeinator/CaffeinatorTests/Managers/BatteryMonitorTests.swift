//
//  BatteryMonitorTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class BatteryMonitorTests: XCTestCase {

    final class MutableLevel {
        var level: Int? = 100
        func get() -> Int? { level }
    }

    final class MutableAC {
        var onAC: Bool = false
        func get() -> Bool { onAC }
    }

    var levels: MutableLevel!
    var ac: MutableAC!
    var sut: BatteryMonitor!
    var lowBatteryFireCount = 0

    override func setUp() async throws {
        try await super.setUp()
        levels = MutableLevel()
        ac = MutableAC()
        let levelSource = levels!
        let acSource = ac!
        sut = BatteryMonitor(batteryLevelProvider: { levelSource.get() },
                             isOnACProvider: { acSource.get() })
        sut.threshold = 20
        sut.onLowBattery = { [weak self] in
            self?.lowBatteryFireCount += 1
        }
        lowBatteryFireCount = 0
    }

    override func tearDown() async throws {
        sut.stopMonitoring()
        try await super.tearDown()
    }

    // MARK: - Level-based hysteresis (on battery)

    func test_aboveThreshold_doesNotFire() {
        levels.level = 50
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 0)
        XCTAssertFalse(sut.hasFired)
    }

    func test_belowThreshold_firesOnce() {
        levels.level = 10
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 1)
        XCTAssertTrue(sut.hasFired)
    }

    func test_belowThreshold_doesNotRefire() {
        levels.level = 10
        sut.checkBattery()
        sut.checkBattery()
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 1)
    }

    func test_hysteresis_recoveryResetsAndRefiresOnNextDrop() {
        levels.level = 10
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 1)

        levels.level = 50
        sut.checkBattery()
        XCTAssertFalse(sut.hasFired)
        XCTAssertEqual(lowBatteryFireCount, 1)

        levels.level = 5
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 2)
    }

    func test_atExactThreshold_doesNotFire() {
        levels.level = 20
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 0)
    }

    func test_nilLevel_doesNotFire() {
        levels.level = nil
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 0)
        XCTAssertFalse(sut.hasFired)
    }

    func test_stopMonitoring_resetsHasFired() {
        levels.level = 10
        sut.checkBattery()
        XCTAssertTrue(sut.hasFired)

        sut.stopMonitoring()
        XCTAssertFalse(sut.hasFired)
    }

    // MARK: - AC power gating

    func test_onAC_belowThreshold_doesNotFire() {
        // Regression: launching Caffeinator while plugged in with battery
        // below threshold previously fired the low-battery notification.
        ac.onAC = true
        levels.level = 10
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 0)
        XCTAssertFalse(sut.hasFired)
    }

    func test_onAC_aboveThreshold_doesNotFire() {
        ac.onAC = true
        levels.level = 80
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 0)
    }

    func test_onAC_doesNotResetHasFired() {
        // If we already fired while on battery, plugging in should not
        // reset hasFired (prevents re-fire when the user briefly toggles
        // AC while still below threshold).
        ac.onAC = false
        levels.level = 10
        sut.checkBattery()
        XCTAssertTrue(sut.hasFired)

        ac.onAC = true
        sut.checkBattery()
        XCTAssertTrue(sut.hasFired)
        XCTAssertEqual(lowBatteryFireCount, 1)
    }

    func test_acThenBatteryStillBelowThreshold_doesNotRefire() {
        ac.onAC = false
        levels.level = 10
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 1)

        ac.onAC = true
        sut.checkBattery()

        ac.onAC = false
        sut.checkBattery()
        // Still hasFired=true and level<threshold, so no re-fire.
        XCTAssertEqual(lowBatteryFireCount, 1)
    }

    func test_acThenRecoveryThenBattery_firesAfresh() {
        // On battery, below threshold → fires
        ac.onAC = false
        levels.level = 10
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 1)

        // Plug in, battery recovers above threshold (AC bypass means
        // checkBattery returns early, but next un-plugged check sees
        // the recovered level and resets hasFired)
        ac.onAC = true
        levels.level = 80
        sut.checkBattery()

        // Unplug while above threshold — resets hasFired
        ac.onAC = false
        sut.checkBattery()
        XCTAssertFalse(sut.hasFired)

        // Drop again
        levels.level = 5
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 2)
    }

    func test_launchedWhilePluggedInBelowThreshold_doesNotFire() {
        // End-to-end regression for the reported bug: user is on AC,
        // battery is below threshold, Caffeinator launches and immediately
        // runs checkBattery — no notification should fire.
        ac.onAC = true
        levels.level = 38
        sut.threshold = 50
        sut.checkBattery()
        XCTAssertEqual(lowBatteryFireCount, 0)
        XCTAssertFalse(sut.hasFired)
    }
}
