//
//  StringUtilities.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/29/26.
//

import Foundation

struct StringUtilities {

    static func formatTimeRemaining(_ remaining: TimeInterval?) -> String? {
        guard let remaining = remaining else {
            return nil
        }

        let total = Int(remaining)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }

        return String(format: "%d:%02d", m, s)
    }

    static func formatStopTime(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}
