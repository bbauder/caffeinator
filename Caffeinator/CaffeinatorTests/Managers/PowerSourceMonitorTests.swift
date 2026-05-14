//
//  PowerSourceMonitorTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class PowerSourceMonitorTests: XCTestCase {

    final class MutableState {
        var onAC: Bool = true
        func get() -> Bool { onAC }
    }

    var state: MutableState!
    var sut: PowerSourceMonitor!
    var unpluggedCount = 0

    override func setUp() async throws {
        try await super.setUp()
        state = MutableState()
        let s = state!
        sut = PowerSourceMonitor(powerStateProvider: { s.get() })
        sut.onUnplugged = { [weak self] in self?.unpluggedCount += 1 }
        unpluggedCount = 0
    }

    override func tearDown() async throws {
        sut.stopMonitoring()
        try await super.tearDown()
    }

    func test_startMonitoring_seedsInitialState() {
        state.onAC = true
        sut.startMonitoring()
        XCTAssertEqual(sut.wasOnAC, true)
    }

    func test_acToAC_doesNotFire() {
        state.onAC = true
        sut.startMonitoring()

        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 0)
    }

    func test_acToBattery_fires() {
        state.onAC = true
        sut.startMonitoring()

        state.onAC = false
        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 1)
    }

    func test_batteryToBattery_doesNotFire() {
        state.onAC = false
        sut.startMonitoring()

        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 0)
    }

    func test_batteryToAC_doesNotFire() {
        state.onAC = false
        sut.startMonitoring()

        state.onAC = true
        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 0)
    }

    func test_fullCycle_acThenBatteryThenAcThenBattery_firesTwice() {
        state.onAC = true
        sut.startMonitoring()

        state.onAC = false
        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 1)

        state.onAC = true
        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 1)

        state.onAC = false
        sut.handlePowerSourceChange()
        XCTAssertEqual(unpluggedCount, 2)
    }

    func test_stopMonitoring_clearsWasOnAC() {
        state.onAC = true
        sut.startMonitoring()
        sut.stopMonitoring()
        XCTAssertNil(sut.wasOnAC)
    }
}
