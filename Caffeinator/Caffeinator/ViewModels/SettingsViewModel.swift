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
            persistence.preventSystemSleep = preventSystemSleep
        }
    }

    @Published var preventDisplaySleep: Bool {
        didSet {
            persistence.preventDisplaySleep = preventDisplaySleep
            if declareUserActivity, let wakeManager, wakeManager.isActive {
                userActivityManager.start(preventDisplaySleep: preventDisplaySleep)
            }
        }
    }

    @Published var preventScreenSaver: Bool {
        didSet {
            persistence.preventScreenSaver = preventScreenSaver
        }
    }

    @Published var hideActivationOptionsWhileActive: Bool {
        didSet {
            persistence.hideActivationOptionsWhileActive = hideActivationOptionsWhileActive
        }
    }

    @Published var showRecentDurations: Bool {
        didSet {
            persistence.showRecentDurations = showRecentDurations
        }
    }

    @Published var showCountdown: Bool {
        didSet {
            persistence.showCountdown = showCountdown
        }
    }

    @Published var animateIcon: Bool {
        didSet {
            persistence.animateIcon = animateIcon
        }
    }

    @Published var declareUserActivity: Bool {
        didSet {
            persistence.declareUserActivity = declareUserActivity
            userActivityManager.isEnabled = declareUserActivity
            if declareUserActivity, let wakeManager, wakeManager.isActive {
                userActivityManager.start(preventDisplaySleep: preventDisplaySleep)
            } else {
                userActivityManager.stop()
            }
        }
    }

    @Published var autoDisableOnLowBattery: Bool {
        didSet {
            persistence.autoDisableOnLowBattery = autoDisableOnLowBattery
            if autoDisableOnLowBattery {
                notificationManager.requestPermission()
                batteryMonitor.startMonitoring(threshold: lowBatteryThreshold)
            } else {
                batteryMonitor.stopMonitoring()
            }
        }
    }

    @Published var lowBatteryThreshold: Int {
        didSet {
            persistence.lowBatteryThreshold = lowBatteryThreshold
        }
    }

    @Published var autoDisableNotificationsEnabled: Bool {
        didSet {
            persistence.autoDisableNotificationsEnabled = autoDisableNotificationsEnabled
            notificationManager.notificationsEnabled = autoDisableNotificationsEnabled
        }
    }

    @Published var autoDisableOnUnpluggedPower: Bool {
        didSet {
            persistence.autoDisableOnUnpluggedPower = autoDisableOnUnpluggedPower
            if autoDisableOnUnpluggedPower {
                notificationManager.requestPermission()
                powerSourceMonitor.startMonitoring()
            } else {
                powerSourceMonitor.stopMonitoring()
            }
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

    @Published private(set) var mruEntries: [MRUEntry] = []

    var isRunningFromDerivedData: Bool {
        Bundle.main.bundlePath.contains("DerivedData")
    }

    var isAnySystemEnabled: Bool {
        preventSystemSleep || preventDisplaySleep || preventScreenSaver
    }

    let persistence: SettingsPersistenceManager
    let notificationManager: NotificationManager
    let batteryMonitor: BatteryMonitor
    let powerSourceMonitor: PowerSourceMonitor
    let userActivityManager: UserActivityManager
    private static let maxMRU = 3
    private var wakeManagerCancellable: AnyCancellable?

    weak var wakeManager: WakeAssertionManager? {
        didSet {
            observeWakeManager()
        }
    }

    init(persistence: SettingsPersistenceManager,
         notificationManager: NotificationManager,
         batteryMonitor: BatteryMonitor,
         powerSourceMonitor: PowerSourceMonitor,
         userActivityManager: UserActivityManager) {
        self.persistence = persistence
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
        mruEntries = persistence.mruEntries

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

    func recordMRU(_ entry: MRUEntry) {
        mruEntries.removeAll {
            $0 == entry
        }
        mruEntries.insert(entry, at: 0)

        if mruEntries.count > Self.maxMRU {
            mruEntries = Array(mruEntries.prefix(Self.maxMRU))
        }

        persistence.mruEntries = mruEntries
    }
}
