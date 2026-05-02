//
//  StatusItemController.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/29/26.
//

import AppKit
import SwiftUI
import Combine

final class StatusItemController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let wakeManager: WakeAssertionManager
    private let settings: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?

    init(wakeManager: WakeAssertionManager, settings: SettingsViewModel) {
        self.wakeManager = wakeManager
        self.settings = settings
        super.init()

        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else {
            return
        }

        button.image = nil
        button.title = ""
        button.imagePosition = .imageOnly

        let iconView = StatusBarIconView(wakeManager: wakeManager)
        let hostingView = NSHostingView(rootView: iconView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(hostingView)

        wakeManager.$isActive
            .receive(on: RunLoop.main)
            .sink { isActive in
                let indefiniteMode = self.wakeManager.menuBarTimeLabel == nil
                self.statusItem.length = isActive && !indefiniteMode ? 60 : 20
            }
            .store(in: &cancellables)
        
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    nonisolated func menuNeedsUpdate(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            rebuildMenu(menu)
        }
    }

    // MARK: - Menu Construction

    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let hideInactive = settings.hideActivationOptionsWhileActive &&
                           wakeManager.isActive

        // MRU section
        if !hideInactive && settings.showRecentDurations {
            let entries = settings.mruEntries
            if !entries.isEmpty {
                let header = NSMenuItem(title: L.recents, action: nil, keyEquivalent: "")
                header.isEnabled = false
                menu.addItem(header)

                for entry in entries {
                    let item = NSMenuItem(title: mruTitle(for: entry), action: #selector(activateMRU(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = entry
                    item.indentationLevel = 1
                    item.state = isMRUEntryActive(entry) ? .on : .off
                    menu.addItem(item)
                }
                menu.addItem(.separator())
            }
        }

        // Stop item
        if wakeManager.isActive {
            let item = NSMenuItem(title: L.stopKeepingAwake, action: #selector(deactivateWake), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            menu.addItem(.separator())
        }

        // Keep Awake submenu
        if !hideInactive {
            let keepAwakeItem = NSMenuItem(title: L.keepAwake, action: nil, keyEquivalent: "")
            let keepAwakeSubmenu = NSMenu()

            let isIndefinite = wakeManager.isActive &&
                               wakeManager.selectedDuration == nil &&
                               wakeManager.selectedStopTime == nil

            let indefiniteItem = NSMenuItem(title: L.indefinitely, action: #selector(toggleIndefinite), keyEquivalent: "")
            indefiniteItem.target = self
            indefiniteItem.state = isIndefinite ? .on : .off
            keepAwakeSubmenu.addItem(indefiniteItem)

            addDurationItem(to: keepAwakeSubmenu, title: L.forMinutes(30), duration: 30 * 60)
            addDurationItem(to: keepAwakeSubmenu, title: L.forHours(1), duration: 60 * 60)
            addDurationItem(to: keepAwakeSubmenu, title: L.forHours(2), duration: 2 * 60 * 60)

            let customItem = NSMenuItem(title: L.customDuration, action: #selector(showCustomDurationPicker), keyEquivalent: "")
            customItem.target = self
            keepAwakeSubmenu.addItem(customItem)

            if let formattedTime = wakeManager.formattedStopTime {
                let item = NSMenuItem(title: L.untilTime(formattedTime), action: #selector(deactivateWake), keyEquivalent: "")
                item.target = self
                item.state = .on
                keepAwakeSubmenu.addItem(item)
            } else {
                let item = NSMenuItem(title: L.until, action: #selector(showStopAtPicker), keyEquivalent: "")
                item.target = self
                keepAwakeSubmenu.addItem(item)
            }

            keepAwakeItem.submenu = keepAwakeSubmenu
            menu.addItem(keepAwakeItem)
        }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: L.settings, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: L.quitCaffeinator, action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addDurationItem(to menu: NSMenu, title: String, duration: TimeInterval) {
        let item = NSMenuItem(title: title, action: #selector(toggleDuration(_:)), keyEquivalent: "")

        item.target = self
        item.tag = Int(duration)
        item.state = wakeManager.selectedDuration == duration ? .on : .off
        menu.addItem(item)
    }

    // MARK: - MRU Helpers

    private func mruTitle(for entry: MRUEntry) -> String {
        switch entry {
        case .indefinitely:
            return L.indefinitely
        case .duration(let seconds):
            return StringUtilities.formatDuration(seconds)
        case .untilTime(let hour, let minute):
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
            components.hour = hour
            components.minute = minute
            if let date = Calendar.current.date(from: components),
               let formatted = StringUtilities.formatStopTime(date) {
                return L.untilTime(formatted)
            }
            return L.until
        }
    }

    private func isMRUEntryActive(_ entry: MRUEntry) -> Bool {
        guard wakeManager.isActive else {
            return false
        }

        switch entry {
            case .indefinitely:
                return wakeManager.selectedDuration == nil && wakeManager.selectedStopTime == nil
            case .duration(let seconds):
                return wakeManager.selectedDuration == seconds
            case .untilTime(let hour, let minute):
                guard let stopTime = wakeManager.selectedStopTime else {
                    return false
                }
                
                let components = Calendar.current.dateComponents([.hour, .minute], from: stopTime)
                return components.hour == hour && components.minute == minute
        }
    }

    // MARK: - Actions

    private func requireSystemEnabled() -> Bool {
        if settings.hasAnySystemEnabled { return true }
        openSettings()
        return false
    }

    @objc private func toggleIndefinite() {
        let isIndefinite = wakeManager.isActive &&
                           wakeManager.selectedDuration == nil &&
                           wakeManager.selectedStopTime == nil

        if isIndefinite {
            wakeManager.deactivate()
        } else {
            guard requireSystemEnabled() else { return }
            wakeManager.activateIndefinitely()
        }
    }

    @objc private func deactivateWake() {
        wakeManager.deactivate()
    }

    @objc private func showStopAtPicker() {
        guard requireSystemEnabled() else { return }
        StopAtPopoverManager.shared.show(wakeManager: wakeManager)
    }

    @objc private func showCustomDurationPicker() {
        guard requireSystemEnabled() else { return }
        CustomDurationPopoverManager.shared.show(wakeManager: wakeManager)
    }

    @objc private func toggleDuration(_ sender: NSMenuItem) {
        let duration = TimeInterval(sender.tag)

        if wakeManager.selectedDuration == duration {
            wakeManager.deactivate()
        } else {
            guard requireSystemEnabled() else { return }
            wakeManager.activate(for: duration)
        }
    }

    @objc private func activateMRU(_ sender: NSMenuItem) {
        guard let entry = sender.representedObject as? MRUEntry else {
            return
        }

        switch entry {
            case .indefinitely:
                let isIndefinite = wakeManager.isActive &&
                                   wakeManager.selectedDuration == nil &&
                                   wakeManager.selectedStopTime == nil
                if isIndefinite {
                    wakeManager.deactivate()
                } else {
                    guard requireSystemEnabled() else { return }
                    wakeManager.activateIndefinitely()
                }
            case .duration(let seconds):
                if wakeManager.selectedDuration == seconds {
                    wakeManager.deactivate()
                } else {
                    guard requireSystemEnabled() else { return }
                    wakeManager.activate(for: seconds)
                }
            case .untilTime(let hour, let minute):
                if let stopTime = wakeManager.selectedStopTime {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: stopTime)
                    if components.hour == hour && components.minute == minute {
                        wakeManager.deactivate()
                        return
                    }
                }

                guard requireSystemEnabled() else { return }
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
                components.hour = hour
                components.minute = minute
                if let date = Calendar.current.date(from: components) {
                    wakeManager.activate(until: date)
                }
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        // Create an NSWindow with NSHosting​Controller wrapping Settings​View,
        // reusing an existing window if one is already visible.
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let view = SettingsView()
            .environmentObject(settings)
        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hostingController)
        window.title = L.settingsWindowTitle
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Status Bar Icon View

private struct StatusBarIconView: View {
    @ObservedObject var wakeManager: WakeAssertionManager

    var body: some View {
        let isActive = wakeManager.isActive
        let fill = isActive ? wakeManager.fillLevel : 0

        HStack(spacing: 4) {
            CaffeinatorIconView(fillLevel: fill, isActive: isActive)
                .frame(width: 18, height: 18)
                .offset(y: -1)   // improved baseline alignment

            if let timeLabel = wakeManager.menuBarTimeLabel {
                Text(timeLabel)
                    .font(FontPalette.monospacedDigit)
            }
        }
    }
}
