//
//  ProcessWatcherTests.swift
//  CaffeinatorTests
//

import XCTest
import AppKit
@testable import Caffeinator

@MainActor
final class ProcessWatcherTests: XCTestCase {

    var sut: ProcessWatcher!

    override func setUp() async throws {
        try await super.setUp()
        sut = ProcessWatcher()
    }

    func test_initialState_notWatching() {
        XCTAssertFalse(sut.isWatching)
    }

    func test_startWatching_setsIsWatching() {
        sut.startWatching(pid: 100)
        XCTAssertTrue(sut.isWatching)
    }

    func test_stopWatching_clearsWhenAllRemoved() {
        sut.startWatching(pid: 100)
        sut.startWatching(pid: 200)
        sut.stopWatching(pid: 100)
        XCTAssertTrue(sut.isWatching)
        sut.stopWatching(pid: 200)
        XCTAssertFalse(sut.isWatching)
    }

    func test_stopAll_clearsAll() {
        sut.startWatching(pid: 1)
        sut.startWatching(pid: 2)
        sut.startWatching(pid: 3)
        sut.stopAll()
        XCTAssertFalse(sut.isWatching)
    }

    func test_terminationOfWatchedPID_firesCallback() async {
        let expectation = expectation(description: "process terminated")
        sut.onProcessTerminated = { pid in
            XCTAssertEqual(pid, NSRunningApplication.current.processIdentifier)
            expectation.fulfill()
        }
        sut.startWatching(pid: NSRunningApplication.current.processIdentifier)

        postTermination(NSRunningApplication.current)
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.isWatching)
    }

    func test_terminationOfWatchedPID_firesOnAllProcessesTerminatedWhenLast() async {
        let pidExpect = expectation(description: "process")
        let allExpect = expectation(description: "all done")
        sut.onProcessTerminated = { _ in pidExpect.fulfill() }
        sut.onAllProcessesTerminated = { allExpect.fulfill() }
        sut.startWatching(pid: NSRunningApplication.current.processIdentifier)

        postTermination(NSRunningApplication.current)
        await fulfillment(of: [pidExpect, allExpect], timeout: 1.0)
    }

    func test_terminationOfUnwatchedPID_doesNotFire() async {
        var processFired = false
        var allFired = false
        sut.onProcessTerminated = { _ in processFired = true }
        sut.onAllProcessesTerminated = { allFired = true }

        postTermination(NSRunningApplication.current)
        await pumpMainRunLoop(times: 5)

        XCTAssertFalse(processFired)
        XCTAssertFalse(allFired)
    }

    func test_terminationWithMissingUserInfo_isIgnored() async {
        var processFired = false
        sut.onProcessTerminated = { _ in processFired = true }
        sut.startWatching(pid: NSRunningApplication.current.processIdentifier)

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            userInfo: nil)

        await pumpMainRunLoop(times: 5)
        XCTAssertFalse(processFired)
        XCTAssertTrue(sut.isWatching) // still watching
    }

    private func postTermination(_ app: NSRunningApplication) {
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            userInfo: [NSWorkspace.applicationUserInfoKey: app])
    }
}
