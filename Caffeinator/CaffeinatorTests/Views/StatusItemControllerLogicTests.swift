//
//  StatusItemControllerLogicTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class StatusItemControllerLogicTests: XCTestCase {

    // MARK: - TooltipBuilder

    func test_tooltip_idle_showsIdleLineOnly() {
        let result = TooltipBuilder.build(isActive: false,
                                          watchedApps: [],
                                          formattedStopTime: nil,
                                          formattedTimeRemaining: nil)
        XCTAssertEqual(result, L.tooltipIdle)
    }

    func test_tooltip_active_indefinite() {
        let result = TooltipBuilder.build(isActive: true,
                                          watchedApps: [],
                                          formattedStopTime: nil,
                                          formattedTimeRemaining: nil)
        XCTAssertTrue(result.contains(L.tooltipActive))
        XCTAssertTrue(result.contains(L.tooltipTimeRemaining(L.tooltipIndefinite)))
    }

    func test_tooltip_active_withWatchedApps_listsBullets() {
        let apps = [
            WatchedProcess(id: 1, name: "Alpha", bundleIdentifier: nil, icon: nil),
            WatchedProcess(id: 2, name: "Bravo", bundleIdentifier: nil, icon: nil),
        ]
        let result = TooltipBuilder.build(isActive: true,
                                          watchedApps: apps,
                                          formattedStopTime: nil,
                                          formattedTimeRemaining: nil)
        XCTAssertTrue(result.contains(L.tooltipActive))
        XCTAssertTrue(result.contains(L.tooltipWatching))
        XCTAssertTrue(result.contains("Alpha"))
        XCTAssertTrue(result.contains("Bravo"))
    }

    func test_tooltip_active_withMoreThanFiveApps_showsAndMore() {
        let apps = (1...8).map {
            WatchedProcess(id: pid_t($0), name: "App\($0)", bundleIdentifier: nil, icon: nil)
        }
        let result = TooltipBuilder.build(isActive: true,
                                          watchedApps: apps,
                                          formattedStopTime: nil,
                                          formattedTimeRemaining: nil)
        XCTAssertTrue(result.contains(L.tooltipAndMore(3)))
    }

    func test_tooltip_active_withStopTime() {
        let result = TooltipBuilder.build(isActive: true,
                                          watchedApps: [],
                                          formattedStopTime: "9:00 AM",
                                          formattedTimeRemaining: "1:00:00")
        XCTAssertTrue(result.contains(L.tooltipTimeRemaining(L.tooltipUntil("9:00 AM"))))
    }

    func test_tooltip_active_withCountdownOnly() {
        let result = TooltipBuilder.build(isActive: true,
                                          watchedApps: [],
                                          formattedStopTime: nil,
                                          formattedTimeRemaining: "1:23:45")
        XCTAssertTrue(result.contains(L.tooltipTimeRemaining("1:23:45")))
    }

    // MARK: - StatusTextBuilder

    func test_statusText_inactive_isNil() {
        XCTAssertNil(StatusTextBuilder.compute(isActive: false,
                                               watchCount: 0,
                                               menuBarTimeLabel: nil))
    }

    func test_statusText_watchingOneApp() {
        XCTAssertEqual(StatusTextBuilder.compute(isActive: true,
                                                 watchCount: 1,
                                                 menuBarTimeLabel: nil),
                       L.statusWatchingApps(1))
    }

    func test_statusText_watchingManyApps() {
        XCTAssertEqual(StatusTextBuilder.compute(isActive: true,
                                                 watchCount: 5,
                                                 menuBarTimeLabel: nil),
                       L.statusWatchingApps(5))
    }

    func test_statusText_timedWithLabel() {
        XCTAssertEqual(StatusTextBuilder.compute(isActive: true,
                                                 watchCount: 0,
                                                 menuBarTimeLabel: "1:00:00"),
                       "1:00:00")
    }

    func test_statusText_activeIndefiniteFallsBackToKeepingAwake() {
        XCTAssertEqual(StatusTextBuilder.compute(isActive: true,
                                                 watchCount: 0,
                                                 menuBarTimeLabel: nil),
                       L.statusKeepingAwake)
    }
}
