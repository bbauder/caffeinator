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
            // Required to satisfy the App protocol requirement.
            // We manage the Settings window manually via AppKit (see StatusItemController)
            EmptyView()
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
