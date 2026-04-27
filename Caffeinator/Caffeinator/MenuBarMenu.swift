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

            Divider()

            Button("5 Minutes") {
                wakeManager.activate(for: 5 * 60)
            }
            Button("10 Minutes") {
                wakeManager.activate(for: 10 * 60)
            }
            Button("15 Minutes") {
                wakeManager.activate(for: 15 * 60)
            }

            Divider()

            Button("30 Minutes") {
                wakeManager.activate(for: 30 * 60)
            }
            Button("1 Hour") {
                wakeManager.activate(for: 60 * 60)
            }

            Divider()

            Button("2 Hours") {
                wakeManager.activate(for: 2 * 60 * 60)
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
