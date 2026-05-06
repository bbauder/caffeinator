//
//  Strings.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import Foundation

enum L {
    static let keepAwakeIndefinitely = NSLocalizedString("keepAwakeIndefinitely", comment: "")

    static func keepAwakeFor(minutes: Int) -> String {
        if minutes == 1 {
            return NSLocalizedString("keepAwakeForOneMinute", comment: "")
        }
        return String(format: NSLocalizedString("keepAwakeForMinutes", comment: ""), minutes)
    }

    static func keepAwakeFor(hours: Int) -> String {
        if hours == 1 {
            return NSLocalizedString("keepAwakeForOneHour", comment: "")
        }
        return String(format: NSLocalizedString("keepAwakeForHours", comment: ""), hours)
    }

    static let keepAwakeUntil = NSLocalizedString("keepAwakeUntil", comment: "")

    static func keepAwakeUntilTime(_ time: String) -> String {
        String(format: NSLocalizedString("keepAwakeUntilTime", comment: ""), time)
    }

    static let keepAwakeUntilLabel = NSLocalizedString("keepAwakeUntilLabel", comment: "")
    static let customDuration = NSLocalizedString("customDuration", comment: "")
    static let stopKeepingAwake = NSLocalizedString("stopKeepingAwake", comment: "")

    static func hours(_ count: Int) -> String {
        String(format: NSLocalizedString("hours", comment: ""), count)
    }

    static func minutes(_ count: Int) -> String {
        String(format: NSLocalizedString("minutes", comment: ""), count)
    }

    static func endsAt(_ time: String) -> String {
        String(format: NSLocalizedString("endsAt", comment: ""), time)
    }

    static let cancel = NSLocalizedString("cancel", comment: "")
    static let start = NSLocalizedString("start", comment: "")
    static let settings = NSLocalizedString("settings", comment: "")
    static let quitCaffeinator = NSLocalizedString("quitCaffeinator", comment: "")

    static let settingsGeneral = NSLocalizedString("settingsGeneral", comment: "")
    static let settingsAppearance = NSLocalizedString("settingsAppearance", comment: "")
    static let settingsSleepPrevention = NSLocalizedString("settingsSleepPrevention", comment: "")
    static let settingsAutoDisable = NSLocalizedString("settingsAutoDisable", comment: "")
    static let settingsAutoDisablePlaceholder = NSLocalizedString("settingsAutoDisablePlaceholder", comment: "")
    static let settingsPreventSystemSleep = NSLocalizedString("settingsPreventSystemSleep", comment: "")
    static let settingsPreventDisplaySleep = NSLocalizedString("settingsPreventDisplaySleep", comment: "")
    static let settingsPreventAutoLock = NSLocalizedString("settingsPreventAutoLock", comment: "")
    static let settingsMenu = NSLocalizedString("settingsMenu", comment: "")
    static let settingsHideActivationOptions = NSLocalizedString("settingsHideActivationOptions", comment: "")
    static let done = NSLocalizedString("done", comment: "")
    static let settingsWindowTitle = NSLocalizedString("settingsWindowTitle", comment: "")
    static let keepAwake = NSLocalizedString("keepAwake", comment: "")

    static let recents = NSLocalizedString("recents", comment: "")
    static let indefinitely = NSLocalizedString("indefinitely", comment: "")

    static func forMinutes(_ count: Int) -> String {
        if count == 1 {
            return NSLocalizedString("forOneMinute", comment: "")
        }
        return String(format: NSLocalizedString("forMinutes", comment: ""), count)
    }

    static func forHours(_ count: Int) -> String {
        if count == 1 {
            return NSLocalizedString("forOneHour", comment: "")
        }
        return String(format: NSLocalizedString("forHours", comment: ""), count)
    }

    static let until = NSLocalizedString("until", comment: "")

    static func untilTime(_ time: String) -> String {
        String(format: NSLocalizedString("untilTime", comment: ""), time)
    }

    static let settingsShowRecents = NSLocalizedString("settingsShowRecents", comment: "")
    static let settingsNoSystemsEnabledTitle = NSLocalizedString("settingsNoSystemsEnabledTitle", comment: "")
    static let settingsNoSystemsEnabledMessage = NSLocalizedString("settingsNoSystemsEnabledMessage", comment: "")
    static let settingsShowCountdown = NSLocalizedString("settingsShowCountdown", comment: "")
    static let settingsAnimateIconWhileActive = NSLocalizedString("settingsAnimateIconWhileActive", comment: "")
    static let settingsLaunchAtLogin = NSLocalizedString("settingsLaunchAtLogin", comment: "")

    static let tooltipActive = NSLocalizedString("tooltipActive", comment: "")
    static let tooltipIdle = NSLocalizedString("tooltipIdle", comment: "")
    static let tooltipPrevented = NSLocalizedString("tooltipPrevented", comment: "")
    static let tooltipAllowed = NSLocalizedString("tooltipAllowed", comment: "")
    static let tooltipIndefinite = NSLocalizedString("tooltipIndefinite", comment: "")

    static func tooltipSystemSleep(_ status: String) -> String {
        String(format: NSLocalizedString("tooltipSystemSleep", comment: ""), status)
    }

    static func tooltipDisplaySleep(_ status: String) -> String {
        String(format: NSLocalizedString("tooltipDisplaySleep", comment: ""), status)
    }

    static func tooltipAutoLock(_ status: String) -> String {
        String(format: NSLocalizedString("tooltipAutoLock", comment: ""), status)
    }

    static func tooltipTimeRemaining(_ value: String) -> String {
        String(format: NSLocalizedString("tooltipTimeRemaining", comment: ""), value)
    }

    static func tooltipUntil(_ time: String) -> String {
        String(format: NSLocalizedString("tooltipUntil", comment: ""), time)
    }
}
