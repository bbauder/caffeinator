//
//  BatteryMonitor.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import Foundation
import IOKit.ps

@MainActor
class BatteryMonitor {

    var onLowBattery: (() -> Void)?

    private let batteryLevelProvider: () -> Int?
    private let isOnACProvider: () -> Bool
    private var batteryTask: Task<Void, Never>?
    var threshold: Int = 20
    private(set) var hasFired = false

    init(batteryLevelProvider: @escaping () -> Int? = BatteryMonitor.iokitBatteryLevel,
         isOnACProvider: @escaping () -> Bool = PowerSourceMonitor.iokitOnAC) {
        self.batteryLevelProvider = batteryLevelProvider
        self.isOnACProvider = isOnACProvider
    }

    func startMonitoring(threshold: Int) {
        self.threshold = threshold
        hasFired = false
        batteryTask?.cancel()

        batteryTask = Task {
            while !Task.isCancelled {
                checkBattery()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func stopMonitoring() {
        batteryTask?.cancel()
        batteryTask = nil
        hasFired = false
    }

    func checkBattery() {
        // "Low battery" only applies when running on battery power.
        // If plugged in, charge is rising — not a low-battery situation.
        // hasFired is intentionally preserved so we don't re-fire on a
        // brief AC excursion below the threshold.
        if isOnACProvider() {
            return
        }

        guard let level = batteryLevelProvider() else {
            return
        }

        if level >= threshold {
            hasFired = false
            return
        }

        guard !hasFired else {
            return
        }

        hasFired = true
        onLowBattery?()
    }

    nonisolated static let iokitBatteryLevel: () -> Int? = {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              let capacity = description[kIOPSCurrentCapacityKey] as? Int else {
            return nil
        }

        return capacity
    }
}
