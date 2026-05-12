//
//  NotificationManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import UserNotifications

@MainActor
class NotificationManager {

    var notificationsEnabled: Bool = true

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    func sendLowBatteryNotification(threshold: Int) {
        guard notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.autoDisableNotificationTitle
        content.body = L.autoDisableNotificationBody(threshold)

        let request = UNNotificationRequest(identifier: "autoDisableLowBattery",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func sendUnpluggedNotification() {
        guard notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.notificationStoppedTitle
        content.body = L.notificationUnpluggedBody

        let request = UNNotificationRequest(identifier: "autoDisableUnplugged",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
