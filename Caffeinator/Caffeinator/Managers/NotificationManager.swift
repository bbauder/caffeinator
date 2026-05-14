//
//  NotificationManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import UserNotifications

protocol NotificationDelivering {

    func requestAuthorization()
    func deliver(_ request: UNNotificationRequest)
}

struct UNCenterNotificationDelivery: NotificationDelivering {

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    func deliver(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

@MainActor
class NotificationManager {

    var notificationsEnabled: Bool = true

    private let delivery: NotificationDelivering

    init(delivery: NotificationDelivering = UNCenterNotificationDelivery()) {
        self.delivery = delivery
    }

    func requestPermission() {
        delivery.requestAuthorization()
    }

    func sendLowBatteryNotification(threshold: Int) {
        guard notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.autoDisableNotificationTitle
        content.body = L.autoDisableNotificationBody(threshold)

        let request = UNNotificationRequest(identifier: "autoDisableLowBattery",
                                            content: content,
                                            trigger: nil)
        delivery.deliver(request)
    }

    func sendTimerExpiredNotification() {
        guard notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.notificationTimerExpiredTitle
        content.body = L.notificationTimerExpiredBody

        let request = UNNotificationRequest(identifier: "timerExpired",
                                            content: content,
                                            trigger: nil)
        delivery.deliver(request)
    }

    func sendUnpluggedNotification() {
        guard notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.notificationStoppedTitle
        content.body = L.notificationUnpluggedBody

        let request = UNNotificationRequest(identifier: "autoDisableUnplugged",
                                            content: content,
                                            trigger: nil)
        delivery.deliver(request)
    }
}
