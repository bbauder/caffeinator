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

    var levels: MutableLevel!
    var sut: BatteryMonitor!
    var lowBatteryFireCount = 0

    override func setUp() async throws {
        try await super.setUp()
        levels = MutableLevel()
        let providerSource = levels!
        sut = BatteryMonitor(batteryLevelProvider: { providerSource.get() })
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
}
