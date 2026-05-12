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

    var onTimerEnd: (() -> Void)?

    var settings: SettingsViewModel? {
        didSet {
            observeSettings()
        }
    }

    private var systemSleepAssertionID: IOPMAssertionID = 0
    private var displaySleepAssertionID: IOPMAssertionID = 0
    private var screensaverAssertionID: IOPMAssertionID = 0

    private var hasSystemSleepAssertion = false
    private var hasDisplaySleepAssertion = false
    private var hasScreensaverAssertion = false

    private var timerTask: Task<Void, Never>?
    private var totalDuration: TimeInterval?
    private var cancellables = Set<AnyCancellable>()

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
        createAssertions()

        isActive = true
        timeRemaining = nil
        selectedDuration = nil

        settings?.recordMRU(.indefinitely)
    }

    func activateForProcessWatch() {
        deactivate()
        createAssertions()

        isActive = true
        timeRemaining = nil
        selectedDuration = nil
    }

    func activate(for duration: TimeInterval) {
        deactivate()
        createAssertions()

        isActive = true
        timeRemaining = duration
        selectedDuration = duration
        totalDuration = duration

        settings?.recordMRU(.duration(duration))
        startCountdown()
    }

    func activate(until date: Date) {
        deactivate()

        var targetDate = date
        if targetDate <= Date.now {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }

        createAssertions()
        isActive = true

        let duration = targetDate.timeIntervalSince(Date.now)
        timeRemaining = duration
        totalDuration = duration
        selectedStopTime = targetDate

        let components = Calendar.current.dateComponents([.hour, .minute], from: targetDate)
        if let hour = components.hour, let minute = components.minute {
            settings?.recordMRU(.untilTime(hour: hour, minute: minute))
        }

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
            releaseAllAssertions()
            isActive = false
        }
    }

    // MARK: - Settings Observation

    private func observeSettings() {
        cancellables.removeAll()
        
        guard let settings else {
            return
        }

        settings.$preventSystemSleep
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateAssertions() }
            .store(in: &cancellables)

        settings.$preventDisplaySleep
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateAssertions() }
            .store(in: &cancellables)

        settings.$preventScreenSaver
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateAssertions() }
            .store(in: &cancellables)
    }

    private func updateAssertions() {
        guard isActive else {
            return
        }
        
        guard let s = settings else {
            return
        }

        if s.preventSystemSleep && !hasSystemSleepAssertion {
            hasSystemSleepAssertion = createAssertion(type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                                                      id: &systemSleepAssertionID
            )
        } else if !s.preventSystemSleep && hasSystemSleepAssertion {
            IOPMAssertionRelease(systemSleepAssertionID)
            systemSleepAssertionID = 0
            hasSystemSleepAssertion = false
        }

        if s.preventDisplaySleep && !hasDisplaySleepAssertion {
            hasDisplaySleepAssertion = createAssertion(type: kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                       id: &displaySleepAssertionID
            )
        } else if !s.preventDisplaySleep && hasDisplaySleepAssertion {
            IOPMAssertionRelease(displaySleepAssertionID)
            displaySleepAssertionID = 0
            hasDisplaySleepAssertion = false
        }

        if s.preventScreenSaver && !hasScreensaverAssertion {
            hasScreensaverAssertion = createAssertion(type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                                                      id: &screensaverAssertionID
            )
        } else if !s.preventScreenSaver && hasScreensaverAssertion {
            IOPMAssertionRelease(screensaverAssertionID)
            screensaverAssertionID = 0
            hasScreensaverAssertion = false
        }
    }

    // MARK: - Assertion Lifecycle

    private func createAssertions() {
        guard let s = settings else {
            return
        }

        if s.preventSystemSleep {
            hasSystemSleepAssertion = createAssertion(type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                                                      id: &systemSleepAssertionID
            )
        }

        if s.preventDisplaySleep {
            hasDisplaySleepAssertion = createAssertion(type: kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                       id: &displaySleepAssertionID
            )
        }

        if s.preventScreenSaver {
            hasScreensaverAssertion = createAssertion(type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                                                      id: &screensaverAssertionID
            )
        }
    }

    private func releaseAllAssertions() {
        if hasSystemSleepAssertion {
            IOPMAssertionRelease(systemSleepAssertionID)
            systemSleepAssertionID = 0
            hasSystemSleepAssertion = false
        }

        if hasDisplaySleepAssertion {
            IOPMAssertionRelease(displaySleepAssertionID)
            displaySleepAssertionID = 0
            hasDisplaySleepAssertion = false
        }

        if hasScreensaverAssertion {
            IOPMAssertionRelease(screensaverAssertionID)
            screensaverAssertionID = 0
            hasScreensaverAssertion = false
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
            onTimerEnd?()
        }
    }

    private func createAssertion(type: CFString, id: inout IOPMAssertionID) -> Bool {
        let reason = "Caffeinator is keeping this Mac awake" as CFString
        let result = IOPMAssertionCreateWithName(type,
                                                 UInt32(kIOPMAssertionLevelOn),
                                                 reason,
                                                 &id
        )

        return result == kIOReturnSuccess
    }
}
