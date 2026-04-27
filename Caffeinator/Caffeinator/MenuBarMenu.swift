//
//  MenuBarMenu.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/27/26.
//

import SwiftUI

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
