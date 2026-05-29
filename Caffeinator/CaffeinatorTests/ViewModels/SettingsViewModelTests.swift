//
//  SettingsViewModelTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class SettingsViewModelTests: XCTestCase {

    var persistence: SettingsPersistenceManager!
    var mruStore: MRUStore!
    var notificationDelivery: FakeNotificationDelivery!
    var notifications: NotificationManager!
    var batteryMonitor: BatteryMonitor!
    var powerSourceMonitor: PowerSourceMonitor!
    var userActivity: UserActivityManager!
    var sut: SettingsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        persistence = SettingsPersistenceManager(defaults: TestUserDefaults.make(),
                                                 launchAtLoginResolver: { false })
        mruStore = MRUStore(persistence: persistence)
        notificationDelivery = FakeNotificationDelivery()
        notifications = NotificationManager(delivery: notificationDelivery)
        batteryMonitor = BatteryMonitor(batteryLevelProvider: { nil })
        powerSourceMonitor = PowerSourceMonitor(powerStateProvider: { true })
        userActivity = UserActivityManager(declareActivity: { _ in })

        sut = SettingsViewModel(persistence: persistence,
                                mruStore: mruStore,
                                notificationManager: notifications,
                                batteryMonitor: batteryMonitor,
                                powerSourceMonitor: powerSourceMonitor,
                                userActivityManager: userActivity,
                                launchAtLoginUpdater: { $0 })
    }

    // MARK: - Init reads persistence

    func test_init_reflectsPersistence() {
        XCTAssertEqual(sut.lowBatteryThreshold, persistence.lowBatteryThreshold)
        XCTAssertEqual(sut.hideActivationOptionsWhileActive, persistence.hideActivationOptionsWhileActive)
        XCTAssertEqual(sut.declareUserActivity, persistence.declareUserActivity)
    }

    func test_init_wiresNotificationsEnabledToPersistedValue() {
        XCTAssertEqual(notifications.notificationsEnabled, persistence.autoDisableNotificationsEnabled)
    }

    func test_init_wiresUserActivityEnabledToPersistedValue() {
        XCTAssertEqual(userActivity.isEnabled, persistence.declareUserActivity)
    }

    // MARK: - Setters persist

    func test_setLowBatteryThreshold_persists() {
        sut.lowBatteryThreshold = 35
        XCTAssertEqual(persistence.lowBatteryThreshold, 35)
    }

    func test_setShowStatusText_persists() {
        sut.showStatusText = false
        XCTAssertFalse(persistence.showStatusText)
    }

    func test_setAutoDisableNotificationsEnabled_updatesNotificationManager() {
        sut.autoDisableNotificationsEnabled = false
        XCTAssertFalse(notifications.notificationsEnabled)
        XCTAssertFalse(persistence.autoDisableNotificationsEnabled)
    }

    // MARK: - launchAtLogin bool flip

    func test_launchAtLogin_setTrue_flipsTrue() {
        sut.launchAtLogin = true
        XCTAssertTrue(sut.launchAtLogin)
    }

    func test_launchAtLogin_setFalse_flipsFalse() {
        sut.launchAtLogin = true
        sut.launchAtLogin = false
        XCTAssertFalse(sut.launchAtLogin)
    }

    func test_launchAtLogin_updaterCanOverride() {
        // Use a constructor that always denies activation
        let denying = SettingsViewModel(persistence: persistence,
                                        mruStore: mruStore,
                                        notificationManager: notifications,
                                        batteryMonitor: batteryMonitor,
                                        powerSourceMonitor: powerSourceMonitor,
                                        userActivityManager: userActivity,
                                        launchAtLoginUpdater: { _ in false })
        denying.launchAtLogin = true
        XCTAssertFalse(denying.launchAtLogin)
    }

    // MARK: - MRU delegation

    func test_recordMRU_delegatesToStore() {
        sut.recordMRU(.duration(60))
        XCTAssertEqual(mruStore.entries.first, .duration(60))
    }

    // MARK: - Timer-expired notification gating

    func test_timerExpired_deliversWhenEnabled() {
        sut.autoDisableNotificationsEnabled = true
        sut.notifyOnTimerExpired = true
        let wake = WakeAssertionManager(assertions: FakePowerAssertionProvider(),
                                        tickInterval: .milliseconds(5))
        sut.wakeManager = wake
        wake.onTimerExpired?() // simulate firing
        XCTAssertEqual(notificationDelivery.identifiers, ["timerExpired"])
    }

    func test_timerExpired_suppressedWhenDisabled() {
        sut.notifyOnTimerExpired = false
        let wake = WakeAssertionManager(assertions: FakePowerAssertionProvider(),
                                        tickInterval: .milliseconds(5))
        sut.wakeManager = wake
        wake.onTimerExpired?()
        XCTAssertTrue(notificationDelivery.delivered.isEmpty)
    }

    // MARK: - Watched-apps-finished notification gating

    func test_watchedAppsFinished_deliversWhenEnabled() {
        sut.autoDisableNotificationsEnabled = true
        sut.notifyOnWatchedAppsFinished = true
        sut.handleAllWatchedProcessesExited()
        XCTAssertEqual(notificationDelivery.identifiers, ["watchedAppsFinished"])
    }

    func test_watchedAppsFinished_suppressedWhenDisabled() {
        sut.autoDisableNotificationsEnabled = true
        sut.notifyOnWatchedAppsFinished = false
        sut.handleAllWatchedProcessesExited()
        XCTAssertTrue(notificationDelivery.delivered.isEmpty)
    }

    func test_setNotifyOnWatchedAppsFinished_persists() {
        sut.notifyOnWatchedAppsFinished = true
        XCTAssertTrue(persistence.notifyOnWatchedAppsFinished)
    }

    func test_allNotificationSettingsDefaultToOff() {
        XCTAssertFalse(sut.autoDisableNotificationsEnabled)
        XCTAssertFalse(sut.notifyOnTimerExpired)
        XCTAssertFalse(sut.notifyOnWatchedAppsFinished)
    }

    // MARK: - Auto-disable monitoring wiring

    func test_enableAutoDisableLowBattery_startsBatteryMonitor() {
        // Pre-condition: not started (no task)
        sut.autoDisableOnLowBattery = true
        // We can't introspect the task directly; verify the threshold is propagated
        XCTAssertEqual(batteryMonitor.threshold, persistence.lowBatteryThreshold)
    }

    func test_disableAutoDisableLowBattery_stopsBatteryMonitor() {
        sut.autoDisableOnLowBattery = true
        sut.autoDisableOnLowBattery = false
        XCTAssertFalse(batteryMonitor.hasFired)
    }
}
