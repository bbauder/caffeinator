//
//  SettingsView.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/27/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(L.settingsSleepPrevention) {
                    Toggle(L.settingsPreventSystemSleep, isOn: $settings.preventSystemSleep)
                    Toggle(L.settingsPreventDisplaySleep, isOn: $settings.preventDisplaySleep)
                    Toggle(L.settingsPreventScreenSaver, isOn: $settings.preventScreenSaver)
                }
                Section(L.settingsMenu) {
                    Toggle(L.settingsHideActivationOptions, isOn: $settings.hideActivationOptionsWhileActive)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            HStack {
                Spacer()

                Button(L.done) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .frame(width: 360)
        .onAppear {
            // This is a classic issue with LSUIElement/agent apps — they don't automatically activate
            // (come to the top of the z-stack) when opening windows.
            // The standard fix is to call NSApp​.activate() when the Settings view appears.
            NSApplication.shared.activate()
        }
    }
}
