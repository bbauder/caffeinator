//
//  ProcessWatcher.swift
//  Caffeinator
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

        let pid = app.processIdentifier
        guard watchedPIDs.contains(pid) else {
            return
        }

        watchedPIDs.remove(pid)
        onProcessTerminated?(pid)

        if watchedPIDs.isEmpty {
            onAllProcessesTerminated?()
        }
    }
}
