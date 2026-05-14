//
//  MRUStoreTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class MRUStoreTests: XCTestCase {

    var persistence: SettingsPersistenceManager!
    var store: MRUStore!

    override func setUp() async throws {
        try await super.setUp()
        persistence = SettingsPersistenceManager(defaults: TestUserDefaults.make())
        store = MRUStore(persistence: persistence)
    }

    func test_emptyOnInit() {
        XCTAssertEqual(store.entries, [])
    }

    func test_record_singleEntry() {
        store.record(.indefinitely)
        XCTAssertEqual(store.entries, [.indefinitely])
    }

    func test_record_dedupsAndMovesToFront() {
        store.record(.duration(60))
        store.record(.indefinitely)
        store.record(.duration(60))
        XCTAssertEqual(store.entries, [.duration(60), .indefinitely])
    }

    func test_record_capsAtMaxEntries() {
        store.record(.duration(60))
        store.record(.duration(120))
        store.record(.duration(180))
        store.record(.duration(240))
        XCTAssertEqual(store.entries.count, store.maxEntries)
        XCTAssertEqual(store.entries.first, .duration(240))
        XCTAssertFalse(store.entries.contains(.duration(60)))
    }

    func test_record_persistsThroughPersistence() {
        store.record(.duration(900))
        XCTAssertEqual(persistence.mruEntries, [.duration(900)])
    }

    func test_record_orderingByRecency() {
        store.record(.duration(60))
        store.record(.untilTime(hour: 9, minute: 0))
        store.record(.indefinitely)
        XCTAssertEqual(store.entries, [.indefinitely, .untilTime(hour: 9, minute: 0), .duration(60)])
    }
}
