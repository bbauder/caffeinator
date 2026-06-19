//
//  CaffeinatorApp.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/23/26.
//

import AppKit
import SwiftUI

@main
struct CaffeinatorApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            // Required to satisfy the App protocol requirement.
            // We manage the Settings window manually via AppKit (see StatusItemController)
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    let wakeManager = WakeAssertionManager()
    let persistence = SettingsPersistenceManager()
    let notificationManager = NotificationManager()
    let batteryMonitor = BatteryMonitor()
    let powerSourceMonitor = PowerSourceMonitor()
    let userActivityManager = UserActivityManager()
    let processDiscovery = ProcessDiscovery()
    let processWatcher = ProcessWatcher()
    let watchedProcessStore = WatchedProcessStore()
    lazy var mruStore = MRUStore(persistence: persistence)
    private var statusItemController: StatusItemController?
    lazy var settings = SettingsViewModel(persistence: persistence,
                                          mruStore: mruStore,
                                          notificationManager: notificationManager,
                                          batteryMonitor: batteryMonitor,
                                          powerSourceMonitor: powerSourceMonitor,
                                          userActivityManager: userActivityManager)
    lazy var watchProcessesViewModel = WatchProcessesViewModel(
        discovery: processDiscovery,
        store: watchedProcessStore,
        processWatcher: processWatcher
    )
    lazy var updateChecker = UpdateChecker(
        currentVersion: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0",
        persistence: persistence
    )

    private let homebrewUpgradeCommand = "brew upgrade caffeinator"

    func applicationDidFinishLaunching(_ notification: Notification) {
        wakeManager.onRecordMRU = { [weak self] entry in
            self?.settings.recordMRU(entry)
        }
        settings.wakeManager = wakeManager

        watchedProcessStore.onFirstProcessAdded = { [weak self] in
            self?.wakeManager.activateForProcessWatch()
        }
        watchedProcessStore.onLastProcessRemoved = { [weak self] in
            self?.wakeManager.deactivate()
        }
        processWatcher.onProcessTerminated = { [weak self] pid in
            self?.watchProcessesViewModel.handleProcessTerminated(pid: pid)
        }
        processWatcher.onAllProcessesTerminated = { [weak self] in
            self?.watchProcessesViewModel.handleAllProcessesTerminated()
            self?.settings.handleAllWatchedProcessesExited()
        }

        settings.updateChecker = updateChecker
        updateChecker.onUpdateAvailable = { [weak self] release in
            self?.presentUpdateAvailableAlert(release: release)
        }
        if settings.checkForUpdates {
            updateChecker.start()
        }

        statusItemController = StatusItemController(
            wakeManager: wakeManager,
            settings: settings,
            watchedProcessStore: watchedProcessStore,
            watchProcessesViewModel: watchProcessesViewModel,
            processWatcher: processWatcher,
            updateChecker: updateChecker
        )
    }

    private func presentUpdateAvailableAlert(release: UpdateRelease) {
        let previousPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = L.updateAvailableTitle(release.version)
        alert.informativeText = """
        \(L.updateAvailableMessage(settings.appVersion))

        \(L.updateAvailableHomebrewHint)
        \(homebrewUpgradeCommand)
        """
        alert.alertStyle = .informational

        alert.addButton(withTitle: L.updateAvailableViewButton)
        alert.addButton(withTitle: L.updateAvailableCopyHomebrewButton)
        alert.addButton(withTitle: L.updateAvailableSkipButton)
        alert.addButton(withTitle: L.updateAvailableLater)

        // Map escape to the "Later" button explicitly. By default NSAlert maps
        // escape to the second button; we want it to be the dismiss action.
        alert.buttons.last?.keyEquivalent = "\u{1b}"

        let response = alert.runModal()

        switch response {
            case .alertFirstButtonReturn:
                NSWorkspace.shared.open(release.releaseURL)
            case .alertSecondButtonReturn:
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(homebrewUpgradeCommand, forType: .string)
            case .alertThirdButtonReturn:
                persistence.skippedUpdateVersion = release.version
            default:
                break
        }

        if previousPolicy == .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
