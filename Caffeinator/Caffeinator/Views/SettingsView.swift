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
        // We dynamically size the Settings window: Let the Form's intrinsic content size dictate
        // the window's size. We use .fixed​Size() so the VStack takes only the space it needs.
        // The NSWindow auto-sizes itself to fit.
        VStack(spacing: 0) {
            Form {
                Section(L.settingsGeneral) {
                    Toggle(L.settingsShowRecents, isOn: $settings.showRecentDurations)
                    Toggle(L.settingsShowCountdown, isOn: $settings.showCountdown)
                    Toggle(L.settingsAnimateIconWhileActive, isOn: $settings.animateIcon)
                    Toggle(L.settingsHideActivationOptions, isOn: $settings.hideActivationOptionsWhileActive)
                }

                Section(L.settingsSleepPrevention) {
                    if !settings.hasAnySystemEnabled {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L.settingsNoSystemsEnabledTitle)
                                    .fontWeight(.semibold)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                Text(L.settingsNoSystemsEnabledMessage)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .font(.callout)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 6)
                    }

                    Toggle(L.settingsPreventSystemSleep, isOn: $settings.preventSystemSleep)
                    Toggle(L.settingsPreventDisplaySleep, isOn: $settings.preventDisplaySleep)
                    Toggle(L.settingsPreventScreenSaver, isOn: $settings.preventScreenSaver)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding(.bottom, -12)

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
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .padding(20)
        .onAppear {
            // This is a known issue with LSUIElement/agent apps — they don't automatically activate
            // (come to the top of the z-stack) when opening windows.
            // The standard fix is to call NSApp​.activate() when the Settings view appears.
            NSApplication.shared.activate()
        }
    }
}
