//
//  WakeAssertionManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/27/26.
//

import Combine
import Foundation
import IOKit.pwr_mgt

protocol PowerAssertionProvider {

    func create(type: CFString, reason: CFString) -> IOPMAssertionID?
    func release(_ id: IOPMAssertionID)
}

struct IOKitPowerAssertionProvider: PowerAssertionProvider {

    func create(type: CFString, reason: CFString) -> IOPMAssertionID? {
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(type,
                                                 UInt32(kIOPMAssertionLevelOn),
                                                 reason,
                                                 &id)
        return result == kIOReturnSuccess ? id : nil
    }

    func release(_ id: IOPMAssertionID) {
        IOPMAssertionRelease(id)
    }
}

@MainActor
class WakeAssertionManager: ObservableObject {

    @Published private(set) var isActive = false
    @Published private(set) var timeRemaining: TimeInterval?
    @Published private(set) var selectedDuration: TimeInterval?
    @Published private(set) var selectedStopTime: Date?

    var onTimerExpired: (() -> Void)?

    var settings: SettingsViewModel? {
        didSet {
            observeSettings()
        }
    }

    private let assertions: PowerAssertionProvider
    private let tickInterval: Duration

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

    init(assertions: PowerAssertionProvider = IOKitPowerAssertionProvider(),
         tickInterval: Duration = .seconds(1)) {
        self.assertions = assertions
        self.tickInterval = tickInterval
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
            if let id = createAssertion(type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString) {
                systemSleepAssertionID = id
                hasSystemSleepAssertion = true
            }
        } else if !s.preventSystemSleep && hasSystemSleepAssertion {
            assertions.release(systemSleepAssertionID)
            systemSleepAssertionID = 0
            hasSystemSleepAssertion = false
        }

        if s.preventDisplaySleep && !hasDisplaySleepAssertion {
            if let id = createAssertion(type: kIOPMAssertionTypeNoDisplaySleep as CFString) {
                displaySleepAssertionID = id
                hasDisplaySleepAssertion = true
            }
        } else if !s.preventDisplaySleep && hasDisplaySleepAssertion {
            assertions.release(displaySleepAssertionID)
            displaySleepAssertionID = 0
            hasDisplaySleepAssertion = false
        }

        if s.preventScreenSaver && !hasScreensaverAssertion {
            if let id = createAssertion(type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString) {
                screensaverAssertionID = id
                hasScreensaverAssertion = true
            }
        } else if !s.preventScreenSaver && hasScreensaverAssertion {
            assertions.release(screensaverAssertionID)
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
            if let id = createAssertion(type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString) {
                systemSleepAssertionID = id
                hasSystemSleepAssertion = true
            }
        }

        if s.preventDisplaySleep {
            if let id = createAssertion(type: kIOPMAssertionTypeNoDisplaySleep as CFString) {
                displaySleepAssertionID = id
                hasDisplaySleepAssertion = true
            }
        }

        if s.preventScreenSaver {
            if let id = createAssertion(type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString) {
                screensaverAssertionID = id
                hasScreensaverAssertion = true
            }
        }
    }

    private func releaseAllAssertions() {
        if hasSystemSleepAssertion {
            assertions.release(systemSleepAssertionID)
            systemSleepAssertionID = 0
            hasSystemSleepAssertion = false
        }

        if hasDisplaySleepAssertion {
            assertions.release(displaySleepAssertionID)
            displaySleepAssertionID = 0
            hasDisplaySleepAssertion = false
        }

        if hasScreensaverAssertion {
            assertions.release(screensaverAssertionID)
            screensaverAssertionID = 0
            hasScreensaverAssertion = false
        }
    }

    private func startCountdown() {
        let interval = tickInterval

        timerTask = Task {
            while let remaining = timeRemaining, remaining > 0 {
                try? await Task.sleep(for: interval)

                if Task.isCancelled {
                    return
                }
                timeRemaining = remaining - 1
            }

            if Task.isCancelled {
                return
            }

            deactivate()
            onTimerExpired?()
        }
    }

    private func createAssertion(type: CFString) -> IOPMAssertionID? {
        let reason = "Caffeinator is keeping this Mac awake" as CFString
        return assertions.create(type: type, reason: reason)
    }
}
