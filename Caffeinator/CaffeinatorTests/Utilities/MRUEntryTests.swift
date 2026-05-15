//
//  MRUEntryTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

final class MRUEntryTests: XCTestCase {

    func test_equality_indefinitely() {
        XCTAssertEqual(MRUEntry.indefinitely, MRUEntry.indefinitely)
    }

    func test_equality_durationMatches() {
        XCTAssertEqual(MRUEntry.duration(60), MRUEntry.duration(60))
        XCTAssertNotEqual(MRUEntry.duration(60), MRUEntry.duration(120))
    }

    func test_equality_untilTimeMatches() {
        XCTAssertEqual(MRUEntry.untilTime(hour: 9, minute: 30),
                       MRUEntry.untilTime(hour: 9, minute: 30))
        XCTAssertNotEqual(MRUEntry.untilTime(hour: 9, minute: 30),
                          MRUEntry.untilTime(hour: 9, minute: 31))
    }

    func test_inequality_acrossCases() {
        XCTAssertNotEqual(MRUEntry.indefinitely, MRUEntry.duration(60))
        XCTAssertNotEqual(MRUEntry.duration(60),
                          MRUEntry.untilTime(hour: 9, minute: 30))
    }

    func test_codable_roundTrip_indefinitely() throws {
        try assertRoundTrip(.indefinitely)
    }

    func test_codable_roundTrip_duration() throws {
        try assertRoundTrip(.duration(3600))
    }

    func test_codable_roundTrip_untilTime() throws {
        try assertRoundTrip(.untilTime(hour: 23, minute: 59))
    }

    private func assertRoundTrip(_ entry: MRUEntry,
                                 file: StaticString = #file,
                                 line: UInt = #line) throws {
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(MRUEntry.self, from: data)

        XCTAssertEqual(decoded, entry, file: file, line: line)
    }
}
