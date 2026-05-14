//
//  UserActivityManagerTests.swift
//  CaffeinatorTests
//

import XCTest
import IOKit.pwr_mgt
@testable import Caffeinator

@MainActor
final class UserActivityManagerTests: XCTestCase {

    final class Counter {
        var count = 0
        func tick() { count += 1 }
    }

    var counter: Counter!
    var sut: UserActivityManager!

    override func setUp() async throws {
        try await super.setUp()
        counter = Counter()
        let c = counter!
        sut = UserActivityManager(declareActivity: { _ in c.tick() },
                                  interval: .milliseconds(10))
    }

    override func tearDown() async throws {
        sut.stop()
        try await super.tearDown()
    }

    func test_notEnabled_doesNotStart() async {
        sut.isEnabled = false
        sut.start(preventDisplaySleep: true)
        XCTAssertNil(sut.task)
        XCTAssertEqual(counter.count, 0)
    }

    func test_preventDisplaySleepFalse_doesNotStart() async {
        sut.isEnabled = true
        sut.start(preventDisplaySleep: false)
        XCTAssertNil(sut.task)
        XCTAssertEqual(counter.count, 0)
    }

    func test_bothConditionsTrue_starts() async {
        sut.isEnabled = true
        sut.start(preventDisplaySleep: true)
        XCTAssertNotNil(sut.task)

        await waitFor(self.counter.count >= 1, timeout: 1.0)
        XCTAssertGreaterThanOrEqual(counter.count, 1)
    }

    func test_stop_cancelsTask() async {
        sut.isEnabled = true
        sut.start(preventDisplaySleep: true)
        XCTAssertNotNil(sut.task)

        sut.stop()
        XCTAssertNil(sut.task)
    }

    func test_restart_resetsTask() async {
        sut.isEnabled = true
        sut.start(preventDisplaySleep: true)
        let first = sut.task
        XCTAssertNotNil(first)

        sut.start(preventDisplaySleep: true)
        XCTAssertNotNil(sut.task)
    }
}
