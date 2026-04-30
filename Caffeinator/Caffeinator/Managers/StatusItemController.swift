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

    init(wakeManager: WakeAssertionManager, settings: SettingsViewModel) {
        self.wakeManager = wakeManager
        self.settings = settings
        super.init()

        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 60)

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
                self.statusItem.length = isActive ? 60 : 20
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

        let hideInactive = settings.hideActivationOptionsWhileActive && wakeManager.isActive
        let isIndefinite = wakeManager.isActive
            && wakeManager.selectedDuration == nil
            && wakeManager.selectedStopTime == nil

        if !hideInactive || isIndefinite {
            let item = NSMenuItem(title: L.keepAwakeIndefinitely, action: #selector(toggleIndefinite), keyEquivalent: "")
            item.target = self
            item.state = isIndefinite ? .on : .off
            menu.addItem(item)
        }

        if let formattedTime = wakeManager.formattedStopTime {
            let item = NSMenuItem(title: L.keepAwakeUntilTime(formattedTime), action: #selector(deactivateWake), keyEquivalent: "")
            item.target = self
            item.state = .on
            menu.addItem(item)
        } else if !hideInactive {
            let item = NSMenuItem(title: L.keepAwakeUntil, action: #selector(showStopAtPicker), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        if !hideInactive {
            let item = NSMenuItem(title: L.customDuration, action: #selector(showCustomDurationPicker), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        if wakeManager.isActive {
            let item = NSMenuItem(title: L.stopKeepingAwake, action: #selector(deactivateWake), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        if !hideInactive {
            menu.addItem(.separator())
            addDurationItem(to: menu, title: L.keepAwakeFor(minutes: 30), duration: 30 * 60)
            addDurationItem(to: menu, title: L.keepAwakeFor(hours: 1), duration: 60 * 60)
            addDurationItem(to: menu, title: L.keepAwakeFor(hours: 2), duration: 2 * 60 * 60)
        } else if wakeManager.selectedDuration != nil {
            menu.addItem(.separator())
            if wakeManager.selectedDuration == 30 * 60 {
                addDurationItem(to: menu, title: L.keepAwakeFor(minutes: 30), duration: 30 * 60)
            } else if wakeManager.selectedDuration == 60 * 60 {
                addDurationItem(to: menu, title: L.keepAwakeFor(hours: 1), duration: 60 * 60)
            } else if wakeManager.selectedDuration == 2 * 60 * 60 {
                addDurationItem(to: menu, title: L.keepAwakeFor(hours: 2), duration: 2 * 60 * 60)
            }
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

    // MARK: - Actions

    @objc private func toggleIndefinite() {
        let isIndefinite = wakeManager.isActive
            && wakeManager.selectedDuration == nil
            && wakeManager.selectedStopTime == nil

        if isIndefinite {
            wakeManager.deactivate()
        } else {
            wakeManager.activateIndefinitely()
        }
    }

    @objc private func deactivateWake() {
        wakeManager.deactivate()
    }

    @objc private func showStopAtPicker() {
        StopAtPopoverManager.shared.show(wakeManager: wakeManager)
    }

    @objc private func showCustomDurationPicker() {
        CustomDurationPopoverManager.shared.show(wakeManager: wakeManager)
    }

    @objc private func toggleDuration(_ sender: NSMenuItem) {
        let duration = TimeInterval(sender.tag)

        if wakeManager.selectedDuration == duration {
            wakeManager.deactivate()
        } else {
            wakeManager.activate(for: duration)
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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

            if let timeLabel = wakeManager.menuBarTimeLabel {
                Text(timeLabel)
                    .font(FontPalette.monospacedDigit)
            }
        }
    }
}
