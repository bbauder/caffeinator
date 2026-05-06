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
            ScrollView(.vertical) {
                Form {
                    Section(L.settingsGeneral) {
                        Toggle(L.settingsLaunchAtLogin, isOn: $settings.launchAtLogin)
                        Toggle(L.settingsHideActivationOptions, isOn: $settings.hideActivationOptionsWhileActive)
                    }

                    Section(L.settingsAppearance) {
                        Toggle(L.settingsShowRecents, isOn: $settings.showRecentDurations)
                        Toggle(L.settingsShowCountdown, isOn: $settings.showCountdown)
                        Toggle(L.settingsAnimateIconWhileActive, isOn: $settings.animateIcon)
                    }

                    Section(L.settingsSleepPrevention) {
                        if !settings.hasAnySystemEnabled {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L.settingsNoSystemsEnabledTitle)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.leading)
                                    Text(L.settingsNoSystemsEnabledMessage)
                                        .foregroundStyle(.secondary)
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
                        Toggle(L.settingsPreventAutoLock, isOn: $settings.preventScreenSaver)
                    }

                    Section(L.settingsAutoDisable) {
                        Text(L.settingsAutoDisablePlaceholder)
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
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
        .frame(width: 420, height: 520)
        .padding(20)
        .onAppear {
            NSApplication.shared.activate()
        }
    }
}
