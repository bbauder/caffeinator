//
//  SettingsViewModel.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import Combine
import Foundation

enum MRUEntry: Codable, Equatable {
    case indefinitely
    case duration(TimeInterval)
    case untilTime(hour: Int, minute: Int)
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var preventSystemSleep: Bool {
        didSet { UserDefaults.standard.set(preventSystemSleep, forKey: "preventSystemSleep") }
    }

    @Published var preventDisplaySleep: Bool {
        didSet { UserDefaults.standard.set(preventDisplaySleep, forKey: "preventDisplaySleep") }
    }

    @Published var preventScreenSaver: Bool {
        didSet { UserDefaults.standard.set(preventScreenSaver, forKey: "preventScreenSaver") }
    }

    @Published var hideActivationOptionsWhileActive: Bool {
        didSet { UserDefaults.standard.set(hideActivationOptionsWhileActive, forKey: "hideActivationOptionsWhileActive") }
    }

    @Published var showRecentDurations: Bool {
        didSet { UserDefaults.standard.set(showRecentDurations, forKey: "showRecentDurations") }
    }

    @Published var showCountdown: Bool {
        didSet { UserDefaults.standard.set(showCountdown, forKey: "showCountdown") }
    }

    @Published var animateIcon: Bool {
        didSet { UserDefaults.standard.set(animateIcon, forKey: "animateIcon") }
    }

    var hasAnySystemEnabled: Bool {
        preventSystemSleep || preventDisplaySleep || preventScreenSaver
    }

    @Published private(set) var mruEntries: [MRUEntry] = []

    private static let maxMRU = 3

    init() {
        let defaults = UserDefaults.standard

        defaults.register(defaults: ["preventSystemSleep": true,
                                     "preventDisplaySleep": false,
                                     "preventScreenSaver": false,
                                     "hideActivationOptionsWhileActive": true,
                                     "showRecentDurations": true,
                                     "showCountdown": true,
                                     "animateIcon": true,
                                    ])

        preventSystemSleep = defaults.bool(forKey: "preventSystemSleep")
        preventDisplaySleep = defaults.bool(forKey: "preventDisplaySleep")
        preventScreenSaver = defaults.bool(forKey: "preventScreenSaver")
        hideActivationOptionsWhileActive = defaults.bool(forKey: "hideActivationOptionsWhileActive")
        showRecentDurations = defaults.bool(forKey: "showRecentDurations")
        showCountdown = defaults.bool(forKey: "showCountdown")
        animateIcon = defaults.bool(forKey: "animateIcon")

        if let data = defaults.data(forKey: "mruEntries"),
           let decoded = try? JSONDecoder().decode([MRUEntry].self, from: data) {
            mruEntries = decoded
        }
    }

    func recordMRU(_ entry: MRUEntry) {
        mruEntries.removeAll { $0 == entry }
        mruEntries.insert(entry, at: 0)

        if mruEntries.count > Self.maxMRU {
            mruEntries = Array(mruEntries.prefix(Self.maxMRU))
        }

        if let data = try? JSONEncoder().encode(mruEntries) {
            UserDefaults.standard.set(data, forKey: "mruEntries")
        }
    }
}
