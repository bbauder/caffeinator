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
        Toggle(L.keepAwakeIndefinitely, isOn: indefiniteBinding)

        if wakeManager.isActive {
            Toggle("Off (use system defaults)", isOn: Binding(
                get: { !wakeManager.isActive },
                set: { newValue in
                    if newValue { wakeManager.deactivate() }
                }
            ))
        }

        Divider()

        durationToggle(L.keepAwakeFor(minutes: 30), duration: 30 * 60)
        durationToggle(L.keepAwakeFor(hours: 1), duration: 60 * 60)
        durationToggle(L.keepAwakeFor(hours: 2), duration: 2 * 60 * 60)

        Divider()

        Button(L.settings) {
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button(L.quitCaffeinator) {
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
