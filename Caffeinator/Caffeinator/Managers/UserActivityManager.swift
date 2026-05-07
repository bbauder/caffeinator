//
//  UserActivityManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import Foundation
import IOKit.pwr_mgt

@MainActor
class UserActivityManager {

    var isEnabled: Bool = false

    private var task: Task<Void, Never>?

    func start(preventDisplaySleep: Bool) {
        stop()
        guard isEnabled, preventDisplaySleep else { return }

        task = Task {
            var assertionID: IOPMAssertionID = 0
            while !Task.isCancelled {
                IOPMAssertionDeclareUserActivity(
                    "Caffeinator user activity" as CFString,
                    kIOPMUserActiveLocal,
                    &assertionID
                )
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
