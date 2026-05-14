//
//  WatchProcessesViewModelTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class WatchProcessesViewModelTests: XCTestCase {

    var discovery: ProcessDiscovery!
    var store: WatchedProcessStore!
    var watcher: ProcessWatcher!
    var sut: WatchProcessesViewModel!

    private func makeDiscovery(_ apps: [FakeApp]) -> ProcessDiscovery {
        ProcessDiscovery(provider: { apps }, currentPID: 0)
    }

    override func setUp() async throws {
        try await super.setUp()
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: "Bravo"),
            FakeApp.make(pid: 3, name: "Charlie"),
        ]
        discovery = makeDiscovery(apps)
        store = WatchedProcessStore()
        watcher = ProcessWatcher()
        sut = WatchProcessesViewModel(discovery: discovery,
                                      store: store,
                                      processWatcher: watcher)
    }

    func test_refreshRunningApps_populatesList() {
        sut.refreshRunningApps()
        XCTAssertEqual(sut.runningApps.map { $0.id }, [1, 2, 3])
    }

    func test_beginPendingSelection_mirrorsStore() {
        store.add(WatchedProcess(id: 1, name: "Alpha", bundleIdentifier: nil, icon: nil))
        store.add(WatchedProcess(id: 2, name: "Bravo", bundleIdentifier: nil, icon: nil))
        sut.beginPendingSelection()
        XCTAssertEqual(sut.pendingSelection, [1, 2])
    }

    func test_togglePending_addsAndRemoves() {
        let p = WatchedProcess(id: 5, name: "X", bundleIdentifier: nil, icon: nil)
        sut.togglePending(process: p)
        XCTAssertTrue(sut.isPending(p))
        sut.togglePending(process: p)
        XCTAssertFalse(sut.isPending(p))
    }

    func test_canCommit_reflectsSelection() {
        XCTAssertFalse(sut.canCommit)
        sut.togglePending(process: WatchedProcess(id: 1, name: "A", bundleIdentifier: nil, icon: nil))
        XCTAssertTrue(sut.canCommit)
    }

    func test_footerText_reflectsSelection() {
        XCTAssertEqual(sut.footerText, L.watchProcessesFooterEmpty)
        sut.togglePending(process: WatchedProcess(id: 1, name: "A", bundleIdentifier: nil, icon: nil))
        XCTAssertEqual(sut.footerText, L.watchProcessesFooterWatching)
    }

    func test_commitSelection_addsNewToStore() {
        sut.refreshRunningApps()
        sut.togglePending(process: sut.runningApps[0])
        sut.togglePending(process: sut.runningApps[1])
        sut.commitSelection()

        XCTAssertEqual(store.processes.count, 2)
        XCTAssertTrue(store.contains(pid: 1))
        XCTAssertTrue(store.contains(pid: 2))
        XCTAssertTrue(watcher.isWatching)
    }

    func test_commitSelection_removesMissingFromStore() {
        sut.refreshRunningApps()
        sut.togglePending(process: sut.runningApps[0])
        sut.togglePending(process: sut.runningApps[1])
        sut.commitSelection()

        // Now deselect Bravo
        sut.beginPendingSelection()
        sut.togglePending(process: sut.runningApps[1])
        sut.commitSelection()

        XCTAssertTrue(store.contains(pid: 1))
        XCTAssertFalse(store.contains(pid: 2))
    }

    func test_handleProcessTerminated_removesFromStoreAndWatcher() {
        let p = WatchedProcess(id: 100, name: "X", bundleIdentifier: nil, icon: nil)
        store.add(p)
        watcher.startWatching(pid: 100)

        sut.handleProcessTerminated(pid: 100)

        XCTAssertFalse(store.contains(pid: 100))
        XCTAssertFalse(watcher.isWatching)
    }

    func test_handleAllProcessesTerminated_clearsEverything() {
        store.add(WatchedProcess(id: 1, name: "A", bundleIdentifier: nil, icon: nil))
        store.add(WatchedProcess(id: 2, name: "B", bundleIdentifier: nil, icon: nil))
        watcher.startWatching(pid: 1)
        watcher.startWatching(pid: 2)

        sut.handleAllProcessesTerminated()

        XCTAssertTrue(store.isEmpty)
        XCTAssertFalse(watcher.isWatching)
    }
}
