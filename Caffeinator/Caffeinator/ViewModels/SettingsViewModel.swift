//
//  SettingsViewModel.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import Combine
import Foundation
import ServiceManagement

@MainActor
class SettingsViewModel: ObservableObject {

    @Published var hideActivationOptionsWhileActive: Bool {
        didSet {
            updateHideActivationOptions()
        }
    }

    @Published var showRecentDurations: Bool {
        didSet {
            updateShowRecentDurations()
        }
    }

    @Published var showStatusText: Bool {
        didSet {
            updateShowStatusText()
        }
    }

    @Published var animateIcon: Bool {
        didSet {
            updateAnimateIcon()
        }
    }

    @Published var declareUserActivity: Bool {
        didSet {
            updateUserActivity()
        }
    }

    @Published var autoDisableOnLowBattery: Bool {
        didSet {
            updateLowBatteryMonitoring()
        }
    }

    @Published var lowBatteryThreshold: Int {
        didSet {
            persistence.lowBatteryThreshold = lowBatteryThreshold
        }
    }

    @Published var autoDisableNotificationsEnabled: Bool {
        didSet {
            updateNotificationPreferences()
        }
    }

    @Published var notifyOnTimerExpired: Bool {
        didSet {
            updateNotifyOnTimerExpired()
        }
    }

    @Published var notifyOnWatchedAppsFinished: Bool {
        didSet {
            updateNotifyOnWatchedAppsFinished()
        }
    }

    @Published var autoDisableOnUnpluggedPower: Bool {
        didSet {
            updateUnplugMonitoring()
        }
    }

    typealias LaunchAtLoginUpdater = (Bool) -> Bool
    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else {
                return
            }

            let resolved = launchAtLoginUpdater(launchAtLogin)
            if resolved != launchAtLogin {
                launchAtLogin = resolved
            }
        }
    }

    let persistence: SettingsPersistenceManager
    let mruStore: MRUStore
    let notificationManager: NotificationManager
    let batteryMonitor: BatteryMonitor
    let powerSourceMonitor: PowerSourceMonitor
    let userActivityManager: UserActivityManager

    private let launchAtLoginUpdater: LaunchAtLoginUpdater
    private var wakeManagerCancellable: AnyCancellable?

    weak var wakeManager: WakeAssertionManager? {
        didSet {
            observeWakeManager()
        }
    }

    init(persistence: SettingsPersistenceManager,
         mruStore: MRUStore,
         notificationManager: NotificationManager,
         batteryMonitor: BatteryMonitor,
         powerSourceMonitor: PowerSourceMonitor,
         userActivityManager: UserActivityManager,
         launchAtLoginUpdater: @escaping LaunchAtLoginUpdater = SettingsViewModel.defaultLaunchAtLoginUpdater) {
        self.persistence = persistence
        self.mruStore = mruStore
        self.notificationManager = notificationManager
        self.batteryMonitor = batteryMonitor
        self.powerSourceMonitor = powerSourceMonitor
        self.userActivityManager = userActivityManager
        self.launchAtLoginUpdater = launchAtLoginUpdater

        hideActivationOptionsWhileActive = persistence.hideActivationOptionsWhileActive
        showRecentDurations = persistence.showRecentDurations
        showStatusText = persistence.showStatusText
        animateIcon = persistence.animateIcon
        declareUserActivity = persistence.declareUserActivity
        autoDisableOnLowBattery = persistence.autoDisableOnLowBattery
        lowBatteryThreshold = persistence.lowBatteryThreshold
        autoDisableOnUnpluggedPower = persistence.autoDisableOnUnpluggedPower
        autoDisableNotificationsEnabled = persistence.autoDisableNotificationsEnabled
        notifyOnTimerExpired = persistence.notifyOnTimerExpired
        notifyOnWatchedAppsFinished = persistence.notifyOnWatchedAppsFinished
        launchAtLogin = persistence.launchAtLogin

        notificationManager.notificationsEnabled = autoDisableNotificationsEnabled
        userActivityManager.isEnabled = declareUserActivity

        batteryMonitor.onLowBattery = { [weak self] in
            guard let self else {
                return
            }

            self.wakeManager?.deactivate()
            self.notificationManager.sendLowBatteryNotification(threshold: self.lowBatteryThreshold)
        }

        powerSourceMonitor.onUnplugged = { [weak self] in
            guard let self else {
                return
            }
            guard self.autoDisableOnUnpluggedPower,
                  let wakeManager = self.wakeManager, wakeManager.isActive else {
                return
            }

            wakeManager.deactivate()
            self.notificationManager.sendUnpluggedNotification()
        }

        if autoDisableOnLowBattery {
            batteryMonitor.startMonitoring(threshold: lowBatteryThreshold)
        }

        if autoDisableOnUnpluggedPower {
            powerSourceMonitor.startMonitoring()
        }
    }

    // MARK: - Wake Manager Observation

    private func observeWakeManager() {
        wakeManagerCancellable = nil

        guard let wakeManager else {
            return
        }

        wakeManager.onTimerExpired = { [weak self] in
            guard let self, self.notifyOnTimerExpired else {
                return
            }

            self.notificationManager.sendTimerExpiredNotification()
        }

        wakeManagerCancellable = wakeManager.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                guard let self else {
                    return
                }

                if isActive {
                    if self.declareUserActivity {
                        self.userActivityManager.start()
                    }
                } else {
                    self.userActivityManager.stop()
                }
            }
    }

    // MARK: - Setting Updates

    private func updateHideActivationOptions() {
        persistence.hideActivationOptionsWhileActive = hideActivationOptionsWhileActive
    }

    private func updateShowRecentDurations() {
        persistence.showRecentDurations = showRecentDurations
    }

    private func updateShowStatusText() {
        persistence.showStatusText = showStatusText
    }

    private func updateAnimateIcon() {
        persistence.animateIcon = animateIcon
    }

    private func updateUserActivity() {
        persistence.declareUserActivity = declareUserActivity
        userActivityManager.isEnabled = declareUserActivity

        if declareUserActivity,
           let wakeManager,
           wakeManager.isActive {
            userActivityManager.start()
        } else {
            userActivityManager.stop()
        }
    }

    private func updateLowBatteryMonitoring() {
        persistence.autoDisableOnLowBattery = autoDisableOnLowBattery

        if autoDisableOnLowBattery {
            notificationManager.requestPermission()
            batteryMonitor.startMonitoring(threshold: lowBatteryThreshold)
        } else {
            batteryMonitor.stopMonitoring()
        }
    }

    private func updateUnplugMonitoring() {
        persistence.autoDisableOnUnpluggedPower = autoDisableOnUnpluggedPower

        if autoDisableOnUnpluggedPower {
            notificationManager.requestPermission()
            powerSourceMonitor.startMonitoring()
        } else {
            powerSourceMonitor.stopMonitoring()
        }
    }

    private func updateNotificationPreferences() {
        persistence.autoDisableNotificationsEnabled = autoDisableNotificationsEnabled
        notificationManager.notificationsEnabled = autoDisableNotificationsEnabled
    }

    private func updateNotifyOnTimerExpired() {
        persistence.notifyOnTimerExpired = notifyOnTimerExpired

        if notifyOnTimerExpired {
            notificationManager.requestPermission()
        }
    }

    private func updateNotifyOnWatchedAppsFinished() {
        persistence.notifyOnWatchedAppsFinished = notifyOnWatchedAppsFinished

        if notifyOnWatchedAppsFinished {
            notificationManager.requestPermission()
        }
    }

    // MARK: - External event handlers

    /// Called when the OS reports that all watched processes have terminated
    /// naturally (not via user-initiated stop). Fires a notification gated
    /// by `notifyOnWatchedAppsFinished`.
    func handleAllWatchedProcessesExited() {
        guard notifyOnWatchedAppsFinished else {
            return
        }

        notificationManager.sendWatchedAppsFinishedNotification()
    }

    func recordMRU(_ entry: MRUEntry) {
        mruStore.record(entry)
    }

    nonisolated static let defaultLaunchAtLoginUpdater: LaunchAtLoginUpdater = { desired in
        if Bundle.main.bundlePath.contains("DerivedData") {
            return false
        }

        do {
            if desired {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return desired
        } catch {
            return SMAppService.mainApp.status == .enabled
        }
    }
}
