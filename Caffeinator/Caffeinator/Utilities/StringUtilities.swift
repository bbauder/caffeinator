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
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    static func formatStopTime(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60

        if hours > 0 && minutes > 0 {
            let hourPart = hours == 1 ? "1 Hour" : "\(hours) Hours"
            let minPart = minutes == 1 ? "1 Minute" : "\(minutes) Minutes"
            return "\(hourPart) \(minPart)"
        } else if hours > 0 {
            return hours == 1 ? "1 Hour" : "\(hours) Hours"
        } else {
            return minutes == 1 ? "1 Minute" : "\(minutes) Minutes"
        }
    }
}
