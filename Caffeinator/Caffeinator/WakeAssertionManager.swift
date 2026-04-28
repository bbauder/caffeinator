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

    var formattedStopTime: String? {
        guard let stopTime = selectedStopTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: stopTime)
    }

    func activateIndefinitely() {
        deactivate()
        guard createAssertion() else { return }
        isActive = true
        timeRemaining = nil
        selectedDuration = nil
    }

    func activate(for duration: TimeInterval) {
        deactivate()
        guard createAssertion() else { return }
        isActive = true
        timeRemaining = duration
        selectedDuration = duration

        startCountdown()
    }

    func activate(until date: Date) {
        deactivate()

        var targetDate = date
        if targetDate <= Date.now {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }

        guard createAssertion() else { return }
        isActive = true
        timeRemaining = targetDate.timeIntervalSince(Date.now)
        selectedStopTime = targetDate

        startCountdown()
    }

    func deactivate() {
        timerTask?.cancel()
        timerTask = nil
        timeRemaining = nil
        selectedDuration = nil
        selectedStopTime = nil

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
                if Task.isCancelled { return }
                timeRemaining = remaining - 1
            }
            deactivate()
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
