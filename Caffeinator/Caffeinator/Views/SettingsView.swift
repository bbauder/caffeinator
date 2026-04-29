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
        VStack {
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

            HStack {
                Spacer()

                Button(L.done) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 380, minHeight: 250)
    }
}
