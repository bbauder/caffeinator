//
//  FakeNotificationDelivery.swift
//  CaffeinatorTests
//

import Foundation
import UserNotifications
@testable import Caffeinator

final class FakeNotificationDelivery: NotificationDelivering, @unchecked Sendable {

    private(set) var authorizationRequests = 0
    private(set) var delivered: [UNNotificationRequest] = []

    func requestAuthorization() {
        authorizationRequests += 1
    }

    func deliver(_ request: UNNotificationRequest) {
        delivered.append(request)
    }

    var identifiers: [String] { delivered.map { $0.identifier } }
    var titles: [String] { delivered.map { $0.content.title } }
    var bodies: [String] { delivered.map { $0.content.body } }
}
