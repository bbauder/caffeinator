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
                        HStack {
                            Toggle(L.settingsLaunchAtLogin, isOn: $settings.launchAtLogin)
                            InfoButton(popoverText: L.settingsLaunchAtLoginHelp)
                        }
                        HStack {
                            Toggle(L.settingsHideActivationOptions, isOn: $settings.hideActivationOptionsWhileActive)
                            InfoButton(popoverText: L.settingsHideActivationOptionsHelp)
                        }
                    }

                    Section(L.settingsAppearance) {
                        HStack {
                            Toggle(L.settingsShowRecents, isOn: $settings.showRecentDurations)
                            InfoButton(popoverText: L.settingsRecentDurationsHelp)
                        }
                        HStack {
                            Toggle(L.settingsShowStatusText, isOn: $settings.showStatusText)
                            InfoButton(popoverText: L.settingsStatusTextHelp)
                        }
                        HStack {
                            Toggle(L.settingsAnimateIconWhileActive, isOn: $settings.animateIcon)
                            InfoButton(popoverText: L.settingsAnimateIconHelp)
                        }
                    }

                    Section(L.settingsSleepPrevention) {
                        if !settings.isAnySystemEnabled {
                            // Display a banner if no sleep systems are enabled
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
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                            .padding(.bottom, 4)
                        }

                        HStack {
                            Toggle(L.settingsPreventSystemSleep, isOn: $settings.preventSystemSleep)
                            InfoButton(popoverText: L.settingsPreventSystemSleepHelp)
                        }
                        HStack {
                            Toggle(L.settingsPreventDisplaySleep, isOn: $settings.preventDisplaySleep)
                            InfoButton(popoverText: L.settingsPreventDisplaySleepHelp)
                        }
                        HStack {
                            Toggle(L.settingsPreventAutoLock, isOn: $settings.preventScreenSaver)
                            InfoButton(popoverText: L.settingsPreventScreenSaverHelp)
                        }
                        HStack {
                            Toggle(L.settingsDeclareUserActivity, isOn: $settings.declareUserActivity)
                            InfoButton(popoverText: L.settingsDeclareUserActivityPopover)
                        }
                    }

                    Section(L.settingsAutoDisable) {
                        HStack {
                            Toggle(L.settingsDisableOnLowBattery, isOn: $settings.autoDisableOnLowBattery)
                            InfoButton(popoverText: L.settingsLowBatteryHelp)
                        }

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

                        HStack {
                            Toggle(L.settingsDisableOnUnpluggedPower, isOn: $settings.autoDisableOnUnpluggedPower)
                            InfoButton(popoverText: L.settingsUnplugHelp)
                        }
                    }

                    Section(L.settingsNotifications) {
                        HStack {
                            Toggle(L.settingsAutoDisableNotificationsEnabled, isOn: $settings.autoDisableNotificationsEnabled)
                            InfoButton(popoverText: L.settingsAutoDisableNotificationsHelp)
                        }
                        HStack {
                            Toggle(L.settingsNotifyOnTimerExpired, isOn: $settings.notifyOnTimerExpired)
                            InfoButton(popoverText: L.settingsNotifyOnTimerExpiredHelp)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }

            HStack {
                Spacer()

                Button(L.done) {
                    // Dismiss when the user hits Return--Done gets styled as the default button
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 4)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 480, height: 540)
        .padding(12)
        .onAppear {
            NSApplication.shared.activate()
        }
        .onExitCommand {
            // Dismiss when the user hits Esc
            dismiss()
        }
    }
}
