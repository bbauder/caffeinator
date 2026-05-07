//
//  SettingsViewModel.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import Combine
import Foundation
import ServiceManagement

enum MRUEntry: Codable, Equatable {
    case indefinitely
    case duration(TimeInterval)
    case untilTime(hour: Int, minute: Int)
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var preventSystemSleep: Bool {
        didSet {
            updateSystemSleepPrevention()
        }
    }

    @Published var preventDisplaySleep: Bool {
        didSet {
            updateDisplaySleepPrevention()
        }
    }

    @Published var preventScreenSaver: Bool {
        didSet {
            updateScreenSaverPrevention()
        }
    }

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

    @Published var showCountdown: Bool {
        didSet {
            updateShowCountdown()
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

    @Published var autoDisableOnUnpluggedPower: Bool {
        didSet {
            updateUnplugMonitoring()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else {
                return
            }
            
            if isRunningFromDerivedData {
                launchAtLogin = false
                return
            }

            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    var isRunningFromDerivedData: Bool {
        Bundle.main.bundlePath.contains("DerivedData")
    }

    var isAnySystemEnabled: Bool {
        preventSystemSleep || preventDisplaySleep || preventScreenSaver
    }

    let persistence: SettingsPersistenceManager
    let mruStore: MRUStore
    let notificationManager: NotificationManager
    let batteryMonitor: BatteryMonitor
    let powerSourceMonitor: PowerSourceMonitor
    let userActivityManager: UserActivityManager
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
         userActivityManager: UserActivityManager) {
        self.persistence = persistence
        self.mruStore = mruStore
        self.notificationManager = notificationManager
        self.batteryMonitor = batteryMonitor
        self.powerSourceMonitor = powerSourceMonitor
        self.userActivityManager = userActivityManager

        preventSystemSleep = persistence.preventSystemSleep
        preventDisplaySleep = persistence.preventDisplaySleep
        preventScreenSaver = persistence.preventScreenSaver
        hideActivationOptionsWhileActive = persistence.hideActivationOptionsWhileActive
        showRecentDurations = persistence.showRecentDurations
        showCountdown = persistence.showCountdown
        animateIcon = persistence.animateIcon
        declareUserActivity = persistence.declareUserActivity
        autoDisableOnLowBattery = persistence.autoDisableOnLowBattery
        lowBatteryThreshold = persistence.lowBatteryThreshold
        autoDisableOnUnpluggedPower = persistence.autoDisableOnUnpluggedPower
        autoDisableNotificationsEnabled = persistence.autoDisableNotificationsEnabled
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

        wakeManagerCancellable = wakeManager.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                guard let self else {
                    return
                }

                if isActive {
                    if self.declareUserActivity {
                        self.userActivityManager.start(preventDisplaySleep: self.preventDisplaySleep)
                    }
                } else {
                    self.userActivityManager.stop()
                }
            }
    }

    // MARK: - Setting Updates

    private func updateSystemSleepPrevention() {
        persistence.preventSystemSleep = preventSystemSleep
    }

    private func updateDisplaySleepPrevention() {
        persistence.preventDisplaySleep = preventDisplaySleep

        if declareUserActivity,
           let wakeManager,
           wakeManager.isActive {
            userActivityManager.start(preventDisplaySleep: preventDisplaySleep)
        }
    }

    private func updateScreenSaverPrevention() {
        persistence.preventScreenSaver = preventScreenSaver
    }

    private func updateHideActivationOptions() {
        persistence.hideActivationOptionsWhileActive = hideActivationOptionsWhileActive
    }

    private func updateShowRecentDurations() {
        persistence.showRecentDurations = showRecentDurations
    }

    private func updateShowCountdown() {
        persistence.showCountdown = showCountdown
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
            userActivityManager.start(preventDisplaySleep: preventDisplaySleep)
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

    func recordMRU(_ entry: MRUEntry) {
        mruStore.record(entry)
    }
}
