//
//  SettingsViewModel.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import Combine
import Foundation
import IOKit.ps
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

    @Published var autoDisableOnLowBattery: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableOnLowBattery, forKey: "autoDisableOnLowBattery")
            if autoDisableOnLowBattery {
                notificationManager.requestPermission()
                startBatteryMonitoring()
            } else {
                stopBatteryMonitoring()
            }
        }
    }

    @Published var lowBatteryThreshold: Int {
        didSet {
            UserDefaults.standard.set(lowBatteryThreshold, forKey: "lowBatteryThreshold")
        }
    }

    @Published var autoDisableOnUnpluggedPower: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableOnUnpluggedPower, forKey: "autoDisableOnUnpluggedPower")
            if autoDisableOnUnpluggedPower {
                notificationManager.requestPermission()
                startPowerSourceMonitoring()
            } else {
                stopPowerSourceMonitoring()
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
    private var batteryTask: Task<Void, Never>?
    private var powerSourceRunLoopSource: CFRunLoopSource?
    private static let maxMRU = 3
    weak var wakeManager: WakeAssertionManager?

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
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

        let derivedData = Bundle.main.bundlePath.contains("DerivedData")
        launchAtLogin = !derivedData && SMAppService.mainApp.status == .enabled

        if let data = defaults.data(forKey: "mruEntries"),
           let decoded = try? JSONDecoder().decode([MRUEntry].self, from: data) {
            mruEntries = decoded
        }

        if autoDisableOnLowBattery {
            startBatteryMonitoring()
        }
        if autoDisableOnUnpluggedPower {
            startPowerSourceMonitoring()
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

    // MARK: - Battery Monitoring

    private func startBatteryMonitoring() {
        batteryTask?.cancel()

        batteryTask = Task {
            while !Task.isCancelled {
                checkBattery()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    private func stopBatteryMonitoring() {
        batteryTask?.cancel()
        batteryTask = nil
    }

    private func checkBattery() {
        guard autoDisableOnLowBattery,
              let wakeManager, wakeManager.isActive,
              let level = currentBatteryLevel(),
              level < lowBatteryThreshold else {
            return
        }

        wakeManager.deactivate()
        notificationManager.sendLowBatteryNotification(threshold: lowBatteryThreshold)
    }

    private func currentBatteryLevel() -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              let capacity = description[kIOPSCurrentCapacityKey] as? Int else {
            return nil
        }
        return capacity
    }

    // MARK: - Power Source Monitoring

    private func startPowerSourceMonitoring() {
        stopPowerSourceMonitoring()

        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let vm = Unmanaged<SettingsViewModel>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated {
                vm.handlePowerSourceChange()
            }
        }, context)?.takeRetainedValue() else { return }

        powerSourceRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    private func stopPowerSourceMonitoring() {
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            powerSourceRunLoopSource = nil
        }
    }

    private func handlePowerSourceChange() {
        guard autoDisableOnUnpluggedPower,
              let wakeManager, wakeManager.isActive else { return }

        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let powerType = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as String?

        if powerType == kIOPSBatteryPowerValue as String {
            wakeManager.deactivate()
            notificationManager.sendUnpluggedNotification()
        }
    }
}
