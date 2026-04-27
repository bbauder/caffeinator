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
