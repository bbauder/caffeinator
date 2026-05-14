//
//  StatusItemViewLogic.swift
//  Caffeinator
//

import Foundation

enum TooltipBuilder {

    static let maxWatchedAppsShown = 5

    static func build(isActive: Bool,
                      preventSystemSleep: Bool,
                      preventDisplaySleep: Bool,
                      preventScreenSaver: Bool,
                      watchedApps: [WatchedProcess],
                      formattedStopTime: String?,
                      formattedTimeRemaining: String?) -> String {
        let status: (Bool) -> String = { isActive && $0 ? L.tooltipPrevented : L.tooltipAllowed }

        var lines: [String] = []

        lines.append(isActive ? L.tooltipActive : L.tooltipIdle)
        lines.append("")
        lines.append(L.tooltipSystemSleep(status(preventSystemSleep)))
        lines.append(L.tooltipDisplaySleep(status(preventDisplaySleep)))
        lines.append(L.tooltipAutoLock(status(preventScreenSaver)))

        if isActive {
            if !watchedApps.isEmpty {
                lines.append("")
                lines.append(L.tooltipWatching)
                for app in watchedApps.prefix(maxWatchedAppsShown) {
                    lines.append("  \u{2022} \(app.name)")
                }
                if watchedApps.count > maxWatchedAppsShown {
                    lines.append("  \u{2022} \(L.tooltipAndMore(watchedApps.count - maxWatchedAppsShown))")
                }
            } else if let stopTime = formattedStopTime {
                lines.append(L.tooltipTimeRemaining(L.tooltipUntil(stopTime)))
            } else if let countdown = formattedTimeRemaining {
                lines.append(L.tooltipTimeRemaining(countdown))
            } else {
                lines.append(L.tooltipTimeRemaining(L.tooltipIndefinite))
            }
        }

        return lines.joined(separator: "\n")
    }
}

enum StatusTextBuilder {

    static func compute(isActive: Bool,
                        watchCount: Int,
                        menuBarTimeLabel: String?) -> String? {
        guard isActive else {
            return nil
        }

        if watchCount > 0 {
            return L.statusWatchingApps(watchCount)
        }

        if let timeLabel = menuBarTimeLabel {
            return timeLabel
        }

        return L.statusKeepingAwake
    }
}
