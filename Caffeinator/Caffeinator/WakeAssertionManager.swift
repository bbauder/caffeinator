//
//  WakeAssertionManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/27/26.
//

import Combine
import Foundation
import IOKit.pwr_mgt

@MainActor
class WakeAssertionManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var timeRemaining: TimeInterval?

    private var assertionID: IOPMAssertionID = 0
    private var timerTask: Task<Void, Never>?

    var menuBarIcon: String {
        if isActive {
            return "cup.and.heat.waves.fill"
        }
        return "cup.and.saucer.fill"
    }

    var menuBarTimeLabel: String? {
        formattedTimeRemaining
    }

    var formattedTimeRemaining: String? {
        guard let remaining = timeRemaining else { return nil }
        let total = Int(remaining)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    func activateIndefinitely() {
        deactivate()
        guard createAssertion() else { return }
        isActive = true
        timeRemaining = nil
    }

    func activate(for duration: TimeInterval) {
        deactivate()
        guard createAssertion() else { return }
        isActive = true
        timeRemaining = duration

        timerTask = Task {
            while let remaining = timeRemaining, remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                timeRemaining = remaining - 1
            }
            deactivate()
        }
    }

    func deactivate() {
        timerTask?.cancel()
        timerTask = nil
        timeRemaining = nil

        if isActive {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            isActive = false
        }
    }

    private func createAssertion() -> Bool {
        let reason = "Caffeinator is keeping this Mac awake" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            UInt32(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        return result == kIOReturnSuccess
    }
}
