//
//  ProcessWatcher.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import AppKit

@MainActor
final class ProcessWatcher {
    var onProcessTerminated: ((pid_t) -> Void)?
    var onAllProcessesTerminated: (() -> Void)?

    private var watchedPIDs = Set<pid_t>()
    private var notificationObserver: Any?

    init() {
        notificationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.handleTermination(notification)
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func startWatching(pid: pid_t) {
        watchedPIDs.insert(pid)
    }

    func stopWatching(pid: pid_t) {
        watchedPIDs.remove(pid)
    }

    func stopAll() {
        watchedPIDs.removeAll()
    }

    var isWatching: Bool {
        !watchedPIDs.isEmpty
    }

    private func handleTermination(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        print(DBG.str("Process with PID \(app.processIdentifier) and name \(app.localizedName ?? "unknown") terminated"))

        let pid = app.processIdentifier
        guard watchedPIDs.contains(pid) else {
            print(DBG.str("Process \(pid) was not being watched"))
            return
        }

        watchedPIDs.remove(pid)
        onProcessTerminated?(pid)

        print(DBG.str("Process \(pid) was being watched and has been removed from the list"))

        if watchedPIDs.isEmpty {
            onAllProcessesTerminated?()
        }
    }
}
