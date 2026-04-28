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

    static let settings = NSLocalizedString("settings", comment: "")
    static let quitCaffeinator = NSLocalizedString("quitCaffeinator", comment: "")
}
