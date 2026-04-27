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

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu()
                .environmentObject(wakeManager)
        } label: {
            if let timeLabel = wakeManager.menuBarTimeLabel {
                Text(timeLabel)
            }
            Image(systemName: wakeManager.menuBarIcon)
        }

        Settings {
            SettingsView()
        }
    }
}
