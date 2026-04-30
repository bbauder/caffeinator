//
//  CaffeinatorApp.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/23/26.
//

import SwiftUI

@main
struct CaffeinatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(delegate.settings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let wakeManager = WakeAssertionManager()
    let settings = SettingsViewModel()
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(
            wakeManager: wakeManager,
            settings: settings
        )
    }
}
