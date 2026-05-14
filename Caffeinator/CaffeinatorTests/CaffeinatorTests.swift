//
//  CaffeinatorTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

// This file intentionally left mostly empty.
// Per-component tests live in their own files in this target.

final class CaffeinatorSmokeTests: XCTestCase {

    @MainActor
    func test_appDelegateTypesInstantiate() {
        XCTAssertNotNil(SettingsPersistenceManager(defaults: TestUserDefaults.make()))
        XCTAssertNotNil(WakeAssertionManager())
        XCTAssertNotNil(BatteryMonitor())
        XCTAssertNotNil(PowerSourceMonitor())
        XCTAssertNotNil(NotificationManager())
        XCTAssertNotNil(UserActivityManager())
        XCTAssertNotNil(ProcessDiscovery())
        XCTAssertNotNil(WatchedProcessStore())
    }
}
