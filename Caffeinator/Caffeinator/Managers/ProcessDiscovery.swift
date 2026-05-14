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

protocol AppEnumerable {

    var processIdentifier: pid_t { get }
    var activationPolicy: NSApplication.ActivationPolicy { get }
    var isTerminated: Bool { get }
    var executableURL: URL? { get }
    var localizedName: String? { get }
    var bundleIdentifier: String? { get }
    var icon: NSImage? { get }
}

extension NSRunningApplication: AppEnumerable {}

@MainActor
final class ProcessDiscovery {

    private let provider: () -> [any AppEnumerable]
    private let currentPID: pid_t

    init(provider: @escaping () -> [any AppEnumerable] = { NSWorkspace.shared.runningApplications },
         currentPID: pid_t = NSRunningApplication.current.processIdentifier) {
        self.provider = provider
        self.currentPID = currentPID
    }

    func discoverGUIApplications() -> [WatchedProcess] {
        provider()
            .filter { app in
                app.activationPolicy == .regular &&
                !app.isTerminated &&
                app.executableURL != nil &&
                app.processIdentifier != currentPID
            }
            .compactMap { app -> WatchedProcess? in
                let name = (app.localizedName ?? app.executableURL?.lastPathComponent ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else {
                    return nil
                }

                return WatchedProcess(id: app.processIdentifier,
                                      name: name,
                                      bundleIdentifier: app.bundleIdentifier,
                                      icon: app.icon)
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }
}
