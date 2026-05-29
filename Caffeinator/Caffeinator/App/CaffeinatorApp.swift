//
//  CaffeinatorApp.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/23/26.
//

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

    func applicationDidFinishLaunching(_ notification: Notification) {
        wakeManager.settings = settings
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

        statusItemController = StatusItemController(
            wakeManager: wakeManager,
            settings: settings,
            watchedProcessStore: watchedProcessStore,
            watchProcessesViewModel: watchProcessesViewModel,
            processWatcher: processWatcher
        )
    }
}
