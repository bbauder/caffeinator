//
//  MRUEntry.swift
//  Caffeinator
//

import Foundation

nonisolated enum MRUEntry: Codable, Equatable, Sendable {

    case indefinitely
    case duration(TimeInterval)
    case untilTime(hour: Int, minute: Int)
}
