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

    private var batteryTask: Task<Void, Never>?
    private var threshold: Int = 20
    private var hasFired = false

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

    private func checkBattery() {
        guard let level = currentBatteryLevel() else {
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
}
