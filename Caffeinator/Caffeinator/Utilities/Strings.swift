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
    static let settingsSleepPrevention = NSLocalizedString("settingsSleepPrevention", comment: "")
    static let settingsPreventSystemSleep = NSLocalizedString("settingsPreventSystemSleep", comment: "")
    static let settingsPreventDisplaySleep = NSLocalizedString("settingsPreventDisplaySleep", comment: "")
    static let settingsPreventScreenSaver = NSLocalizedString("settingsPreventScreenSaver", comment: "")
    static let settingsMenu = NSLocalizedString("settingsMenu", comment: "")
    static let settingsHideActivationOptions = NSLocalizedString("settingsHideActivationOptions", comment: "")
    static let done = NSLocalizedString("done", comment: "")
}
