//
//  StringUtilitiesTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

final class StringUtilitiesTests: XCTestCase {

    // MARK: - formatTimeRemaining

    func test_formatTimeRemaining_nilReturnsNil() {
        XCTAssertNil(StringUtilities.formatTimeRemaining(nil))
    }

    func test_formatTimeRemaining_zero() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(0), "0:00")
    }

    func test_formatTimeRemaining_underOneMinute() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(59), "0:59")
    }

    func test_formatTimeRemaining_exactOneMinute() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(60), "1:00")
    }

    func test_formatTimeRemaining_underOneHour() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(3599), "59:59")
    }

    func test_formatTimeRemaining_exactOneHour() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(3600), "1:00:00")
    }

    func test_formatTimeRemaining_mixedHourMinuteSecond() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(3661), "1:01:01")
    }

    func test_formatTimeRemaining_truncatesFractional() {
        XCTAssertEqual(StringUtilities.formatTimeRemaining(60.9), "1:00")
    }

    // MARK: - formatStopTime

    func test_formatStopTime_nilReturnsNil() {
        XCTAssertNil(StringUtilities.formatStopTime(nil))
    }

    func test_formatStopTime_returnsNonEmpty() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let result = StringUtilities.formatStopTime(date)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.isEmpty)
    }

    // MARK: - formatDuration

    func test_formatDuration_minutesOnly() {
        XCTAssertEqual(StringUtilities.formatDuration(30 * 60), L.durationMinutes(30))
    }

    func test_formatDuration_singleMinute() {
        XCTAssertEqual(StringUtilities.formatDuration(60), L.durationMinutes(1))
    }

    func test_formatDuration_hoursOnly() {
        XCTAssertEqual(StringUtilities.formatDuration(2 * 3600), L.durationHours(2))
    }

    func test_formatDuration_hoursAndMinutes() {
        let expected = L.durationHoursMinutes(L.durationHours(1), L.durationMinutes(30))
        XCTAssertEqual(StringUtilities.formatDuration(3600 + 30 * 60), expected)
    }
}
