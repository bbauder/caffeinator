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

    func activateIndefinitely() {
        deactivate()
        guard createAssertion() else {
            return
        }
        
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
                if Task.isCancelled {
                    return
                }
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
        let result = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                                                 UInt32(kIOPMAssertionLevelOn),
                                                 reason,
                                                 &assertionID)
        return result == kIOReturnSuccess
    }
}
