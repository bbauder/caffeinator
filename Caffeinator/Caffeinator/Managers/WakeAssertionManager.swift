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
    @Published private(set) var selectedDuration: TimeInterval?
    @Published private(set) var selectedStopTime: Date?

    var preventSystemSleep = true
    var preventDisplaySleep = false
    var preventScreenSaver = false

    private var assertionID: IOPMAssertionID = 0
    private var timerTask: Task<Void, Never>?
    private var totalDuration: TimeInterval?

    /* Original version using standard images:
        var menuBarIcon: String {
            if isActive {
                return "cup.and.heat.waves.fill"
            }
            return "cup.and.saucer.fill"
        }
    */
    
    var menuBarIcon: String {
        if isActive {
            return "cup.and.heat.waves.fill"
        }
        return "cup.and.saucer.fill"
    }

    var menuBarTimeLabel: String? {
        return formattedTimeRemaining
    }

    var formattedTimeRemaining: String? {
        return StringUtilities.formatTimeRemaining(timeRemaining)
    }

    var formattedStopTime: String? {
        return StringUtilities.formatStopTime(selectedStopTime)
    }

    var fillLevel: Double {
        if !isActive {
            return 0
        }
        guard let remaining = timeRemaining,
              let total = totalDuration,
              total > 0 else {
            return 1.0
        }
        return max(remaining / total, 0)
    }

    func activateIndefinitely() {
        deactivate()
        guard createAssertion() else {
            return
        }

        isActive = true
        timeRemaining = nil
        selectedDuration = nil
    }

    func activate(for duration: TimeInterval) {
        deactivate()
        guard createAssertion() else {
            return
        }
        
        isActive = true
        timeRemaining = duration
        selectedDuration = duration
        totalDuration = duration

        startCountdown()
    }

    func activate(until date: Date) {
        deactivate()

        var targetDate = date
        if targetDate <= Date.now {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }

        guard createAssertion() else {
            return
        }

        isActive = true
        let duration = targetDate.timeIntervalSince(Date.now)
        timeRemaining = duration
        totalDuration = duration
        selectedStopTime = targetDate

        startCountdown()
    }

    func deactivate() {
        timerTask?.cancel()
        timerTask = nil
        timeRemaining = nil
        selectedDuration = nil
        selectedStopTime = nil
        totalDuration = nil

        if isActive {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            isActive = false
        }
    }

    private func startCountdown() {
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

    private func createAssertion() -> Bool {
        let reason = "Caffeinator is keeping this Mac awake" as CFString
        let result = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                                                 UInt32(kIOPMAssertionLevelOn),
                                                 reason,
                                                 &assertionID
        )
        return result == kIOReturnSuccess
    }
}
