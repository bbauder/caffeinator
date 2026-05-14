//
//  PowerSourceMonitor.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/6/26.
//

import Foundation
import IOKit.ps

@MainActor
class PowerSourceMonitor {

    var onUnplugged: (() -> Void)?

    private let powerStateProvider: () -> Bool
    private var runLoopSource: CFRunLoopSource?
    private(set) var wasOnAC: Bool?

    init(powerStateProvider: @escaping () -> Bool = PowerSourceMonitor.iokitOnAC) {
        self.powerStateProvider = powerStateProvider
    }

    func startMonitoring() {
        stopMonitoring()

        wasOnAC = powerStateProvider()

        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else {
                return
            }

            let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()

            MainActor.assumeIsolated {
                monitor.handlePowerSourceChange()
            }
        }, context)?.takeRetainedValue() else { return }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }

        wasOnAC = nil
    }

    // IOPSNotification​Create​Run​Loop​Source fires on every power source
    // change (battery percentage ticks, charging state updates,
    // time-remaining recalculations), not just plug/unplug events.
    // As a result, we have to track the previous power source state and
    // only fire onUnplugged() for an actual transition from AC to battery.
    func handlePowerSourceChange() {
        let onAC = powerStateProvider()
        let previouslyOnAC = wasOnAC

        wasOnAC = onAC

        if previouslyOnAC == true && !onAC {
            onUnplugged?()
        }
    }

    static let iokitOnAC: () -> Bool = {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let powerType = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as String?

        return powerType != kIOPSBatteryPowerValue as String
    }
}
