//
//  ProcessDiscovery.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import AppKit

struct WatchedProcess: Identifiable, Hashable {
    let id: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WatchedProcess, rhs: WatchedProcess) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class ProcessDiscovery {
    func discoverGUIApplications() -> [WatchedProcess] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular &&
                !app.isTerminated &&
                app.executableURL != nil
            }
            .map { app in
                WatchedProcess(
                    id: app.processIdentifier,
                    name: app.localizedName ?? app.executableURL?.lastPathComponent ?? "Unknown",
                    bundleIdentifier: app.bundleIdentifier,
                    icon: app.icon
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
