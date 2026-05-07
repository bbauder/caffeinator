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
            UserDefaults.standard.set(preventSystemSleep, forKey: "preventSystemSleep")
        }
    }

    @Published var preventDisplaySleep: Bool {
        didSet {
            UserDefaults.standard.set(preventDisplaySleep, forKey: "preventDisplaySleep")
            if declareUserActivity, let wakeManager, wakeManager.isActive {
                userActivityManager.start(preventDisplaySleep: preventDisplaySleep)
            }
        }
    }

    @Published var preventScreenSaver: Bool {
        didSet {
            UserDefaults.standard.set(preventScreenSaver, forKey: "preventScreenSaver")
        }
    }

    @Published var hideActivationOptionsWhileActive: Bool {
        didSet {
            UserDefaults.standard.set(hideActivationOptionsWhileActive, forKey: "hideActivationOptionsWhileActive")
        }
    }

    @Published var showRecentDurations: Bool {
        didSet {
            UserDefaults.standard.set(showRecentDurations, forKey: "showRecentDurations")
        }
    }

    @Published var showCountdown: Bool {
        didSet {
            UserDefaults.standard.set(showCountdown, forKey: "showCountdown")
        }
    }

    @Published var animateIcon: Bool {
        didSet {
            UserDefaults.standard.set(animateIcon, forKey: "animateIcon")
        }
    }

    @Published var declareUserActivity: Bool {
        didSet {
            UserDefaults.standard.set(declareUserActivity, forKey: "declareUserActivity")
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
            UserDefaults.standard.set(autoDisableOnLowBattery, forKey: "autoDisableOnLowBattery")
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
            UserDefaults.standard.set(lowBatteryThreshold, forKey: "lowBatteryThreshold")
        }
    }

    @Published var autoDisableNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableNotificationsEnabled, forKey: "autoDisableNotificationsEnabled")
            notificationManager.notificationsEnabled = autoDisableNotificationsEnabled
        }
    }

    @Published var autoDisableOnUnpluggedPower: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableOnUnpluggedPower, forKey: "autoDisableOnUnpluggedPower")
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

    init(notificationManager: NotificationManager,
         batteryMonitor: BatteryMonitor,
         powerSourceMonitor: PowerSourceMonitor,
         userActivityManager: UserActivityManager) {
        self.notificationManager = notificationManager
        self.batteryMonitor = batteryMonitor
        self.powerSourceMonitor = powerSourceMonitor
        self.userActivityManager = userActivityManager
        let defaults = UserDefaults.standard

        defaults.register(defaults: ["preventSystemSleep": true,
                                     "preventDisplaySleep": false,
                                     "preventScreenSaver": false,
                                     "hideActivationOptionsWhileActive": true,
                                     "showRecentDurations": true,
                                     "showCountdown": true,
                                     "animateIcon": true,
                                     "autoDisableOnLowBattery": false,
                                     "lowBatteryThreshold": 20,
                                     "autoDisableOnUnpluggedPower": false,
                                     "autoDisableNotificationsEnabled": true,
                                     "declareUserActivity": false,
                                    ])

        preventSystemSleep = defaults.bool(forKey: "preventSystemSleep")
        preventDisplaySleep = defaults.bool(forKey: "preventDisplaySleep")
        preventScreenSaver = defaults.bool(forKey: "preventScreenSaver")
        hideActivationOptionsWhileActive = defaults.bool(forKey: "hideActivationOptionsWhileActive")
        showRecentDurations = defaults.bool(forKey: "showRecentDurations")
        showCountdown = defaults.bool(forKey: "showCountdown")
        animateIcon = defaults.bool(forKey: "animateIcon")
        autoDisableOnLowBattery = defaults.bool(forKey: "autoDisableOnLowBattery")
        lowBatteryThreshold = defaults.integer(forKey: "lowBatteryThreshold")
        autoDisableOnUnpluggedPower = defaults.bool(forKey: "autoDisableOnUnpluggedPower")
        autoDisableNotificationsEnabled = defaults.bool(forKey: "autoDisableNotificationsEnabled")
        declareUserActivity = defaults.bool(forKey: "declareUserActivity")

        let derivedData = Bundle.main.bundlePath.contains("DerivedData")
        launchAtLogin = !derivedData && SMAppService.mainApp.status == .enabled

        notificationManager.notificationsEnabled = autoDisableNotificationsEnabled
        userActivityManager.isEnabled = declareUserActivity

        if let data = defaults.data(forKey: "mruEntries"),
           let decoded = try? JSONDecoder().decode([MRUEntry].self, from: data) {
            mruEntries = decoded
        }

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

        if let data = try? JSONEncoder().encode(mruEntries) {
            UserDefaults.standard.set(data, forKey: "mruEntries")
        }
    }
}
