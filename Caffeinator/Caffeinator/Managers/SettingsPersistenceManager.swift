//
//  SettingsPersistenceManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import Foundation
import ServiceManagement

@MainActor
class SettingsPersistenceManager {

    var preventSystemSleep: Bool {
        didSet { defaults.set(preventSystemSleep, forKey: "preventSystemSleep") }
    }

    var preventDisplaySleep: Bool {
        didSet { defaults.set(preventDisplaySleep, forKey: "preventDisplaySleep") }
    }

    var preventScreenSaver: Bool {
        didSet { defaults.set(preventScreenSaver, forKey: "preventScreenSaver") }
    }

    var hideActivationOptionsWhileActive: Bool {
        didSet { defaults.set(hideActivationOptionsWhileActive, forKey: "hideActivationOptionsWhileActive") }
    }

    var showRecentDurations: Bool {
        didSet { defaults.set(showRecentDurations, forKey: "showRecentDurations") }
    }

    var showCountdown: Bool {
        didSet { defaults.set(showCountdown, forKey: "showCountdown") }
    }

    var animateIcon: Bool {
        didSet { defaults.set(animateIcon, forKey: "animateIcon") }
    }

    var declareUserActivity: Bool {
        didSet { defaults.set(declareUserActivity, forKey: "declareUserActivity") }
    }

    var autoDisableOnLowBattery: Bool {
        didSet { defaults.set(autoDisableOnLowBattery, forKey: "autoDisableOnLowBattery") }
    }

    var lowBatteryThreshold: Int {
        didSet { defaults.set(lowBatteryThreshold, forKey: "lowBatteryThreshold") }
    }

    var autoDisableOnUnpluggedPower: Bool {
        didSet { defaults.set(autoDisableOnUnpluggedPower, forKey: "autoDisableOnUnpluggedPower") }
    }

    var autoDisableNotificationsEnabled: Bool {
        didSet { defaults.set(autoDisableNotificationsEnabled, forKey: "autoDisableNotificationsEnabled") }
    }

    private(set) var launchAtLogin: Bool

    var mruEntries: [MRUEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(mruEntries) {
                defaults.set(data, forKey: "mruEntries")
            }
        }
    }

    private let defaults = UserDefaults.standard

    init() {
        defaults.register(defaults: [
            "preventSystemSleep": true,
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
        declareUserActivity = defaults.bool(forKey: "declareUserActivity")
        autoDisableOnLowBattery = defaults.bool(forKey: "autoDisableOnLowBattery")
        lowBatteryThreshold = defaults.integer(forKey: "lowBatteryThreshold")
        autoDisableOnUnpluggedPower = defaults.bool(forKey: "autoDisableOnUnpluggedPower")
        autoDisableNotificationsEnabled = defaults.bool(forKey: "autoDisableNotificationsEnabled")

        let derivedData = Bundle.main.bundlePath.contains("DerivedData")
        launchAtLogin = !derivedData && SMAppService.mainApp.status == .enabled

        if let data = defaults.data(forKey: "mruEntries"),
           let decoded = try? JSONDecoder().decode([MRUEntry].self, from: data) {
            mruEntries = decoded
        } else {
            mruEntries = []
        }
    }
}
