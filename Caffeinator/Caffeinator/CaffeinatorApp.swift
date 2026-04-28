//
//  CaffeinatorApp.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/23/26.
//

import SwiftUI

@main
struct CaffeinatorApp: App {
    @StateObject private var wakeManager = WakeAssertionManager()
    @StateObject private var settings = SettingsViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu()
                .environmentObject(wakeManager)
                .environmentObject(settings)
        } label: {
            if let timeLabel = wakeManager.menuBarTimeLabel {
                Text(timeLabel)
            }
            Image(systemName: wakeManager.menuBarIcon)
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}
