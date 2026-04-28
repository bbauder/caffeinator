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

    static let stopAt = NSLocalizedString("stopAt", comment: "")

    static func stopAtTime(_ time: String) -> String {
        String(format: NSLocalizedString("stopAtTime", comment: ""), time)
    }

    static let customDuration = NSLocalizedString("customDuration", comment: "")
    static let off = NSLocalizedString("off", comment: "")

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
}
