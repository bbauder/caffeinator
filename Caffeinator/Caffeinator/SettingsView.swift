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
        .scenePadding()
        .frame(minWidth: 380, minHeight: 220)
    }
}
