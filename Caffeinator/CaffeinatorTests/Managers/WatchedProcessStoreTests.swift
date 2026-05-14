//
//  WatchedProcessStoreTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class WatchedProcessStoreTests: XCTestCase {

    private func makeProcess(pid: pid_t, name: String) -> WatchedProcess {
        WatchedProcess(id: pid, name: name, bundleIdentifier: nil, icon: nil)
    }

    func test_initiallyEmpty() {
        let store = WatchedProcessStore()
        XCTAssertTrue(store.isEmpty)
        XCTAssertEqual(store.processes.count, 0)
    }

    func test_addFiresOnFirstAddedOnlyOnEmptyToNonEmpty() {
        let store = WatchedProcessStore()
        var firstCount = 0
        store.onFirstProcessAdded = { firstCount += 1 }

        store.add(makeProcess(pid: 1, name: "A"))
        XCTAssertEqual(firstCount, 1)

        store.add(makeProcess(pid: 2, name: "B"))
        XCTAssertEqual(firstCount, 1)
    }

    func test_removeFiresOnLastRemovedOnlyWhenGoingEmpty() {
        let store = WatchedProcessStore()
        var lastCount = 0
        store.onLastProcessRemoved = { lastCount += 1 }

        store.add(makeProcess(pid: 1, name: "A"))
        store.add(makeProcess(pid: 2, name: "B"))

        store.remove(pid: 1)
        XCTAssertEqual(lastCount, 0)

        store.remove(pid: 2)
        XCTAssertEqual(lastCount, 1)
    }

    func test_removeUnknownPidIsNoop() {
        let store = WatchedProcessStore()
        var lastCount = 0
        store.onLastProcessRemoved = { lastCount += 1 }

        store.remove(pid: 42)
        XCTAssertEqual(lastCount, 0)
    }

    func test_removeAllFiresOnLastRemovedOnceWhenNotEmpty() {
        let store = WatchedProcessStore()
        var lastCount = 0
        store.onLastProcessRemoved = { lastCount += 1 }

        store.add(makeProcess(pid: 1, name: "A"))
        store.add(makeProcess(pid: 2, name: "B"))

        store.removeAll()
        XCTAssertEqual(lastCount, 1)
        XCTAssertTrue(store.isEmpty)
    }

    func test_removeAllOnEmptyIsNoop() {
        let store = WatchedProcessStore()
        var lastCount = 0
        store.onLastProcessRemoved = { lastCount += 1 }

        store.removeAll()
        XCTAssertEqual(lastCount, 0)
    }

    func test_containsReflectsState() {
        let store = WatchedProcessStore()
        store.add(makeProcess(pid: 5, name: "X"))
        XCTAssertTrue(store.contains(pid: 5))
        XCTAssertFalse(store.contains(pid: 6))
    }

    func test_allProcessesSortedByLocalizedName() {
        let store = WatchedProcessStore()
        store.add(makeProcess(pid: 1, name: "Charlie"))
        store.add(makeProcess(pid: 2, name: "alpha"))
        store.add(makeProcess(pid: 3, name: "Bravo"))

        let names = store.allProcesses.map { $0.name }
        XCTAssertEqual(names, ["alpha", "Bravo", "Charlie"])
    }
}
