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

    private var isIndefinite: Bool {
        wakeManager.isActive && wakeManager.selectedDuration == nil
    }

    var body: some View {
        Toggle("Activate Indefinitely", isOn: indefiniteBinding)

        Divider()

        durationToggle("5 Minutes", duration: 5 * 60)
        durationToggle("10 Minutes", duration: 10 * 60)
        durationToggle("15 Minutes", duration: 15 * 60)

        Divider()

        durationToggle("30 Minutes", duration: 30 * 60)
        durationToggle("1 Hour", duration: 60 * 60)

        Divider()

        durationToggle("2 Hours", duration: 2 * 60 * 60)

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

    private var indefiniteBinding: Binding<Bool> {
        Binding(
            get: { isIndefinite },
            set: { newValue in
                if newValue {
                    wakeManager.activateIndefinitely()
                } else {
                    wakeManager.deactivate()
                }
            }
        )
    }

    private func durationToggle(_ title: String, duration: TimeInterval) -> some View {
        Toggle(title, isOn: Binding(
            get: { wakeManager.selectedDuration == duration },
            set: { newValue in
                if newValue {
                    wakeManager.activate(for: duration)
                } else {
                    wakeManager.deactivate()
                }
            }
        ))
    }
}
