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
    private let watchedProcessStore: WatchedProcessStore
    private let watchProcessesViewModel: WatchProcessesViewModel
    private let processWatcher: ProcessWatcher
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?

    init(wakeManager: WakeAssertionManager,
         settings: SettingsViewModel,
         watchedProcessStore: WatchedProcessStore,
         watchProcessesViewModel: WatchProcessesViewModel,
         processWatcher: ProcessWatcher) {
        self.wakeManager = wakeManager
        self.settings = settings
        self.watchedProcessStore = watchedProcessStore
        self.watchProcessesViewModel = watchProcessesViewModel
        self.processWatcher = processWatcher
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

        let iconView = StatusBarIconView(wakeManager: wakeManager,
                                         settings: settings,
                                         watchedProcessStore: watchedProcessStore)
        let hostingView = NSHostingView(rootView: iconView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(hostingView)

        Publishers.CombineLatest4(
            wakeManager.$isActive,
            settings.$showStatusText,
            wakeManager.$timeRemaining.map { _ in () }.prepend(()),
            watchedProcessStore.$processes.map { _ in () }.prepend(())
        )
            .receive(on: RunLoop.main)
            .sink { isActive, showStatusText, _, _ in
                if isActive && showStatusText, let label = self.computeStatusText() {
                    let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize,
                                                                weight: .regular)
                    let width = (label as NSString).size(withAttributes: [.font: font]).width
                    self.statusItem.length = ceil(width) + 26
                } else {
                    self.statusItem.length = 20
                }
            }
            .store(in: &cancellables)
        
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        wakeManager.$isActive.map { _ in () }
            .merge(with: wakeManager.$timeRemaining.map { _ in () })
            .merge(with: wakeManager.$selectedStopTime.map { _ in () })
            .merge(with: settings.$preventSystemSleep.map { _ in () })
            .merge(with: settings.$preventDisplaySleep.map { _ in () })
            .merge(with: settings.$preventScreenSaver.map { _ in () })
            .merge(with: watchedProcessStore.$processes.map { _ in () })
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.updateTooltip()
            }
            .store(in: &cancellables)

        updateTooltip()
    }

    // MARK: - Tooltip

    private func updateTooltip() {
        statusItem.button?.toolTip = buildTooltip()
    }

    private func buildTooltip() -> String {
        let isActive = wakeManager.isActive
        let status: (Bool) -> String = { isActive && $0 ? L.tooltipPrevented : L.tooltipAllowed }

        var lines: [String] = []

        lines.append(isActive ? L.tooltipActive : L.tooltipIdle)
        lines.append("")
        lines.append(L.tooltipSystemSleep(status(settings.preventSystemSleep)))
        lines.append(L.tooltipDisplaySleep(status(settings.preventDisplaySleep)))
        lines.append(L.tooltipAutoLock(status(settings.preventScreenSaver)))

        if wakeManager.isActive {
            let watchedApps = watchedProcessStore.allProcesses
            if !watchedApps.isEmpty {
                lines.append("")
                lines.append(L.tooltipWatching)
                let maxShown = 5
                for app in watchedApps.prefix(maxShown) {
                    lines.append("  \u{2022} \(app.name)")
                }
                if watchedApps.count > maxShown {
                    lines.append("  \u{2022} \(L.tooltipAndMore(watchedApps.count - maxShown))")
                }
            } else if let stopTime = wakeManager.formattedStopTime {
                lines.append(L.tooltipTimeRemaining(L.tooltipUntil(stopTime)))
            } else if let countdown = wakeManager.formattedTimeRemaining {
                lines.append(L.tooltipTimeRemaining(countdown))
            } else {
                lines.append(L.tooltipTimeRemaining(L.tooltipIndefinite))
            }
        }

        return lines.joined(separator: "\n")
    }

    private func computeStatusText() -> String? {
        guard wakeManager.isActive else {
            return nil
        }

        let watchCount = watchedProcessStore.processes.count
        if watchCount > 0 {
            return L.statusWatchingApps(watchCount)
        }

        if let timeLabel = wakeManager.menuBarTimeLabel {
            return timeLabel
        }

        return L.statusKeepingAwake
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
            let entries = settings.mruStore.entries

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
                               wakeManager.selectedStopTime == nil &&
                               watchedProcessStore.isEmpty
            let indefiniteItem = NSMenuItem(title: L.indefinitely, action: #selector(toggleIndefinite), keyEquivalent: "")

            indefiniteItem.target = self
            indefiniteItem.state = isIndefinite ? .on : .off
            keepAwakeSubmenu.addItem(indefiniteItem)

            addDurationItem(to: keepAwakeSubmenu, title: L.forMinutes(30), duration: 30 * 60)
            addDurationItem(to: keepAwakeSubmenu, title: L.forHours(1), duration: 60 * 60)
            addDurationItem(to: keepAwakeSubmenu, title: L.forHours(2), duration: 2 * 60 * 60)

            keepAwakeSubmenu.addItem(.separator())
            
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

            let untilAppItem = NSMenuItem(title: L.untilAppExits, action: #selector(showWatchProcessesPicker), keyEquivalent: "")
            untilAppItem.target = self
            if !watchedProcessStore.isEmpty {
                untilAppItem.state = .on
            }
            keepAwakeSubmenu.addItem(untilAppItem)

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
                return wakeManager.selectedDuration == nil &&
                       wakeManager.selectedStopTime == nil &&
                       watchedProcessStore.isEmpty
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

    // MARK: - Watch State

    private func clearWatchState() {
        processWatcher.stopAll()
        watchedProcessStore.removeAll()
    }

    // MARK: - Actions

    private func requireSystemEnabled() -> Bool {
        if settings.isAnySystemEnabled {
            return true
        }

        openSettings()
        return false
    }

    @objc private func toggleIndefinite() {
        let isIndefinite = wakeManager.isActive &&
                           wakeManager.selectedDuration == nil &&
                           wakeManager.selectedStopTime == nil &&
                           watchedProcessStore.isEmpty

        if isIndefinite {
            wakeManager.deactivate()
        } else {
            guard requireSystemEnabled() else {
                return
            }

            clearWatchState()
            wakeManager.activateIndefinitely()
        }
    }

    @objc private func deactivateWake() {
        clearWatchState()
        wakeManager.deactivate()
    }

    @objc private func showStopAtPicker() {
        guard requireSystemEnabled() else {
            return
        }

        clearWatchState()
        StopAtPopoverManager.shared.show(wakeManager: wakeManager)
    }

    @objc private func showCustomDurationPicker() {
        guard requireSystemEnabled() else {
            return
        }

        clearWatchState()
        CustomDurationPopoverManager.shared.show(wakeManager: wakeManager)
    }

    @objc private func toggleDuration(_ sender: NSMenuItem) {
        let duration = TimeInterval(sender.tag)

        if wakeManager.selectedDuration == duration {
            wakeManager.deactivate()
        } else {
            guard requireSystemEnabled() else {
                return
            }

            clearWatchState()
            wakeManager.activate(for: duration)
        }
    }

    @objc private func showWatchProcessesPicker() {
        guard requireSystemEnabled() else {
            return
        }

        WatchProcessesPopoverManager.shared.show(viewModel: watchProcessesViewModel)
    }

    @objc private func activateMRU(_ sender: NSMenuItem) {
        guard let entry = sender.representedObject as? MRUEntry else {
            return
        }

        switch entry {
            case .indefinitely:
                let isIndefinite = wakeManager.isActive &&
                                   wakeManager.selectedDuration == nil &&
                                   wakeManager.selectedStopTime == nil &&
                                   watchedProcessStore.isEmpty
                if isIndefinite {
                    wakeManager.deactivate()
                } else {
                    guard requireSystemEnabled() else {
                        return
                    }

                    clearWatchState()
                    wakeManager.activateIndefinitely()
                }
            case .duration(let seconds):
                if wakeManager.selectedDuration == seconds {
                    wakeManager.deactivate()
                } else {
                    guard requireSystemEnabled() else {
                        return
                    }

                    clearWatchState()
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

                guard requireSystemEnabled() else {
                    return
                }

                clearWatchState()

                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
                components.hour = hour
                components.minute = minute

                if let date = Calendar.current.date(from: components) {
                    wakeManager.activate(until: date)
                }
        }
    }

    @objc private func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsWindowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )

        settingsWindow = window
    }

    @objc private func settingsWindowWillClose(_ notification: Notification) {
        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.willCloseNotification,
            object: notification.object
        )
        settingsWindow = nil
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
