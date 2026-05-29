//
//  NotificationManagerTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class NotificationManagerTests: XCTestCase {

    var delivery: FakeNotificationDelivery!
    var sut: NotificationManager!

    override func setUp() async throws {
        try await super.setUp()
        delivery = FakeNotificationDelivery()
        sut = NotificationManager(delivery: delivery)
    }

    // MARK: - Gating

    func test_lowBattery_suppressedWhenDisabled() {
        sut.notificationsEnabled = false
        sut.sendLowBatteryNotification(threshold: 20)
        XCTAssertTrue(delivery.delivered.isEmpty)
    }

    func test_timerExpired_suppressedWhenDisabled() {
        sut.notificationsEnabled = false
        sut.sendTimerExpiredNotification()
        XCTAssertTrue(delivery.delivered.isEmpty)
    }

    func test_unplugged_suppressedWhenDisabled() {
        sut.notificationsEnabled = false
        sut.sendUnpluggedNotification()
        XCTAssertTrue(delivery.delivered.isEmpty)
    }

    func test_watchedAppsFinished_suppressedWhenDisabled() {
        sut.notificationsEnabled = false
        sut.sendWatchedAppsFinishedNotification()
        XCTAssertTrue(delivery.delivered.isEmpty)
    }

    // MARK: - Delivery

    func test_lowBattery_delivers() {
        sut.sendLowBatteryNotification(threshold: 25)
        XCTAssertEqual(delivery.identifiers, ["autoDisableLowBattery"])
        XCTAssertEqual(delivery.titles, [L.autoDisableNotificationTitle])
        XCTAssertEqual(delivery.bodies, [L.autoDisableNotificationBody(25)])
    }

    func test_timerExpired_delivers() {
        sut.sendTimerExpiredNotification()
        XCTAssertEqual(delivery.identifiers, ["timerExpired"])
        XCTAssertEqual(delivery.titles, [L.notificationTimerExpiredTitle])
        XCTAssertEqual(delivery.bodies, [L.notificationTimerExpiredBody])
    }

    func test_unplugged_delivers() {
        sut.sendUnpluggedNotification()
        XCTAssertEqual(delivery.identifiers, ["autoDisableUnplugged"])
        XCTAssertEqual(delivery.titles, [L.notificationStoppedTitle])
        XCTAssertEqual(delivery.bodies, [L.notificationUnpluggedBody])
    }

    func test_watchedAppsFinished_delivers() {
        sut.sendWatchedAppsFinishedNotification()
        XCTAssertEqual(delivery.identifiers, ["watchedAppsFinished"])
        XCTAssertEqual(delivery.titles, [L.notificationWatchedAppsFinishedTitle])
        XCTAssertEqual(delivery.bodies, [L.notificationWatchedAppsFinishedBody])
    }

    // MARK: - Auth

    func test_requestPermission_delegates() {
        sut.requestPermission()
        sut.requestPermission()
        XCTAssertEqual(delivery.authorizationRequests, 2)
    }
}
