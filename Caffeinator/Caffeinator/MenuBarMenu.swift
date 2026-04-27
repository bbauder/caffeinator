//
//  MenuBarMenu.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/27/26.
//

import SwiftUI

struct MenuBarMenu: View {
    @EnvironmentObject private var wakeManager: WakeAssertionManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        if wakeManager.isActive {
            Button("Deactivate") {
                wakeManager.deactivate()
            }
        } else {
            Button("Activate Indefinitely") {
                wakeManager.activateIndefinitely()
            }

            Button("Activate for 5 Minutes") {
                wakeManager.activate(for: 5 * 60)
            }
        }

        Divider()

        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit Caffeinator") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
