//
//  CaffeinatorApp.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/23/26.
//

import SwiftUI

@main
struct CaffeinatorApp: App {
    var body: some Scene {
        MenuBarExtra("Caffeinator", systemImage: "cup.and.saucer.fill") {
            MenuBarMenu()
        }

        Settings {
            SettingsView()
        }
    }
}

struct MenuBarMenu: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Activate") {
            // TODO: implement activation
        }
        .keyboardShortcut("a")

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
