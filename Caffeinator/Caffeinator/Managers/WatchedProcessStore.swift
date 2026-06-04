//
//  WatchedProcessStore.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import Combine
import Foundation

@MainActor
final class WatchedProcessStore: ObservableObject {

    @Published private(set) var processes: [pid_t: WatchedProcess] = [:]

    var onFirstProcessAdded: (() -> Void)?
    var onLastProcessRemoved: (() -> Void)?
    var isEmpty: Bool {
        processes.isEmpty
    }

    var allProcesses: [WatchedProcess] {
        Array(processes.values).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func add(_ process: WatchedProcess) {
        let wasEmpty = processes.isEmpty

        processes[process.id] = process
        if wasEmpty {
            onFirstProcessAdded?()
        }
    }

    func remove(pid: pid_t) {
        guard processes.removeValue(forKey: pid) != nil else {
            return
        }

        if processes.isEmpty {
            onLastProcessRemoved?()
        }
    }

    func removeAll() {
        guard !processes.isEmpty else {
            return
        }

        processes.removeAll()
        onLastProcessRemoved?()
    }

    func contains(pid: pid_t) -> Bool {
        processes[pid] != nil
    }
}
