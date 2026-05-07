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
                        if !settings.isAnySystemEnabled {
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
                        Toggle(L.settingsDeclareUserActivity, isOn: $settings.declareUserActivity)
                    }

                    Section(L.settingsAutoDisable) {
                        Toggle(L.settingsDisableOnLowBattery, isOn: $settings.autoDisableOnLowBattery)
                        HStack(spacing: 6) {
                            Text(L.settingsThreshold)
                                .foregroundStyle(.secondary)
                            Slider(
                                value: Binding(
                                    get: { Double(settings.lowBatteryThreshold) },
                                    set: { settings.lowBatteryThreshold = Int($0.rounded()) }
                                ),
                                in: 5...50
                            )
                            Text("\(settings.lowBatteryThreshold)%")
                                .monospacedDigit()
                                .frame(width: 36, alignment: .trailing)
                            HStack(spacing: 2) {
                                Button {
                                    if settings.lowBatteryThreshold > 5 {
                                        settings.lowBatteryThreshold -= 1
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.caption2.weight(.semibold))
                                        .frame(width: 16, height: 16)
                                }
                                Button {
                                    if settings.lowBatteryThreshold < 50 {
                                        settings.lowBatteryThreshold += 1
                                    }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.semibold))
                                        .frame(width: 16, height: 16)
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 4)
                        .disabled(!settings.autoDisableOnLowBattery)
                        Toggle(L.settingsDisableOnUnpluggedPower, isOn: $settings.autoDisableOnUnpluggedPower)
                    }

                    Section(L.settingsNotifications) {
                        Toggle(L.settingsAutoDisableNotificationsEnabled, isOn: $settings.autoDisableNotificationsEnabled)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }

            HStack {
                Spacer()

                Button(L.done) {
                    // Dismiss when the user hits Return--default button
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 480, height: 520)
        .padding(20)
        .onAppear {
            NSApplication.shared.activate()
        }
        .onExitCommand {
            // Dismiss when the user hits Esc
            dismiss()
        }
    }
}
