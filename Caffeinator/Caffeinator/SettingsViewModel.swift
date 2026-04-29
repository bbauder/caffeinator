//
//  SettingsViewModel.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import Combine
import Foundation

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

    init() {
        let defaults = UserDefaults.standard
        
        defaults.register(defaults: [
            "preventSystemSleep": true,
            "preventDisplaySleep": false,
            "preventScreenSaver": false,
            "hideActivationOptionsWhileActive": true,
        ])
        
        preventSystemSleep = defaults.bool(forKey: "preventSystemSleep")
        preventDisplaySleep = defaults.bool(forKey: "preventDisplaySleep")
        preventScreenSaver = defaults.bool(forKey: "preventScreenSaver")
        hideActivationOptionsWhileActive = defaults.bool(forKey: "hideActivationOptionsWhileActive")
    }
}
