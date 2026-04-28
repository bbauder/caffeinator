//
//  SettingsView.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/27/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsViewModel

    var body: some View {
        Form {
            Section("Sleep Prevention") {
                Toggle("Prevent system sleep", isOn: $settings.preventSystemSleep)
                Toggle("Prevent display sleep", isOn: $settings.preventDisplaySleep)
                Toggle("Prevent screensaver / lock", isOn: $settings.preventScreenSaver)
            }
            Section("Menu") {
                Toggle("Hide activation options while active", isOn: $settings.hideActivationOptionsWhileActive)
            }
        }
        .formStyle(.grouped)
        .scenePadding()
        .frame(minWidth: 380, minHeight: 220)
    }
}
