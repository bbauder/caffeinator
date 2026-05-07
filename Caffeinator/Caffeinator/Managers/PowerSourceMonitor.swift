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

    private var runLoopSource: CFRunLoopSource?

    func startMonitoring() {
        stopMonitoring()

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
    }

    private func handlePowerSourceChange() {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let powerType = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as String?

        if powerType == kIOPSBatteryPowerValue as String {
            onUnplugged?()
        }
    }
}
