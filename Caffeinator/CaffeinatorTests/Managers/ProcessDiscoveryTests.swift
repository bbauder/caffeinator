//
//  ProcessDiscoveryTests.swift
//  CaffeinatorTests
//

import XCTest
import AppKit
@testable import Caffeinator

@MainActor
final class ProcessDiscoveryTests: XCTestCase {

    func discovery(apps: [FakeApp], currentPID: pid_t = 9999) -> ProcessDiscovery {
        ProcessDiscovery(provider: { apps }, currentPID: currentPID)
    }

    func test_includesRegularNonTerminatedApps() {
        let apps = [FakeApp.make(pid: 1, name: "Alpha")]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_excludesAccessoryApps() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: "Bg", policy: .accessory),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_excludesProhibitedApps() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: "Bg", policy: .prohibited),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_excludesTerminatedApps() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: "Dead", terminated: true),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_excludesAppsWithoutExecutable() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: "NoExe", executableURL: nil),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_excludesCurrentApp() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 42, name: "Caffeinator"),
        ]
        let result = discovery(apps: apps, currentPID: 42).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_dropsAppWithWhitespaceOnlyName() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: "   "),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_dropsAppWithEmptyName() {
        let apps = [
            FakeApp.make(pid: 1, name: "Alpha"),
            FakeApp.make(pid: 2, name: ""),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.map { $0.id }, [1])
    }

    func test_fallsBackToExecutableName() {
        let apps = [
            FakeApp.make(pid: 1,
                         name: nil,
                         executableURL: URL(fileURLWithPath: "/Applications/My App.app/Contents/MacOS/MyApp")),
        ]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.first?.name, "MyApp")
    }

    func test_resultsSortedByLocalizedCaseInsensitive() {
        let apps = [
            FakeApp.make(pid: 1, name: "charlie"),
            FakeApp.make(pid: 2, name: "Alpha"),
            FakeApp.make(pid: 3, name: "bravo"),
        ]
        let names = discovery(apps: apps).discoverGUIApplications().map { $0.name }
        XCTAssertEqual(names, ["Alpha", "bravo", "charlie"])
    }

    func test_trimsName() {
        let apps = [FakeApp.make(pid: 1, name: "  Alpha  ")]
        let result = discovery(apps: apps).discoverGUIApplications()
        XCTAssertEqual(result.first?.name, "Alpha")
    }
}
