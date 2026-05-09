//
//  WatchProcessesViewModel.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import Combine
import Foundation

@MainActor
class WatchProcessesViewModel: ObservableObject {

    @Published private(set) var runningApps: [WatchedProcess] = []
    @Published var pendingSelection = Set<pid_t>()

    private let discovery: ProcessDiscovery
    private let store: WatchedProcessStore
    private let processWatcher: ProcessWatcher
    private var storeCancellable: AnyCancellable?

    var footerText: String {
        if pendingSelection.isEmpty {
            return L.watchProcessesFooterEmpty
        }

        return L.watchProcessesFooterWatching
    }

    var canCommit: Bool {
        !pendingSelection.isEmpty
    }

    init(discovery: ProcessDiscovery,
         store: WatchedProcessStore,
         processWatcher: ProcessWatcher) {
        self.discovery = discovery
        self.store = store
        self.processWatcher = processWatcher

        storeCancellable = store.$processes
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    func refreshRunningApps() {
        runningApps = discovery.discoverGUIApplications()
    }

    func beginPendingSelection() {
        pendingSelection = Set(store.processes.keys)
    }

    func togglePending(process: WatchedProcess) {
        if pendingSelection.contains(process.id) {
            pendingSelection.remove(process.id)
        } else {
            pendingSelection.insert(process.id)
        }
    }

    func isPending(_ process: WatchedProcess) -> Bool {
        pendingSelection.contains(process.id)
    }

    func commitSelection() {
        let currentPIDs = Set(store.processes.keys)

        for pid in currentPIDs where !pendingSelection.contains(pid) {
            store.remove(pid: pid)
            processWatcher.stopWatching(pid: pid)
        }

        for process in runningApps where pendingSelection.contains(process.id) && !currentPIDs.contains(process.id) {
            store.add(process)
            processWatcher.startWatching(pid: process.id)
        }
    }

    func handleProcessTerminated(pid: pid_t) {
        store.remove(pid: pid)
        processWatcher.stopWatching(pid: pid)
    }

    func handleAllProcessesTerminated() {
        store.removeAll()
        processWatcher.stopAll()
    }
}
