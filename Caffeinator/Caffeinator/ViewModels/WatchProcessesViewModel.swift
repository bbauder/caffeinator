//
//  WatchProcessesViewModel.swift
//  Caffeinator
//

import Combine
import Foundation

@MainActor
class WatchProcessesViewModel: ObservableObject {
    @Published private(set) var runningApps: [WatchedProcess] = []

    private let discovery: ProcessDiscovery
    private let store: WatchedProcessStore
    private let processWatcher: ProcessWatcher
    private var storeCancellable: AnyCancellable?

    var watchedApps: [WatchedProcess] {
        store.allProcesses
    }

    var footerText: String {
        if store.isEmpty {
            return L.watchProcessesFooterEmpty
        }
        return L.watchProcessesFooterWatching
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

    func add(process: WatchedProcess) {
        guard !store.contains(pid: process.id) else {
            return
        }
        store.add(process)
        processWatcher.startWatching(pid: process.id)
    }

    func remove(process: WatchedProcess) {
        store.remove(pid: process.id)
        processWatcher.stopWatching(pid: process.id)
    }

    func isWatched(_ process: WatchedProcess) -> Bool {
        store.contains(pid: process.id)
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
