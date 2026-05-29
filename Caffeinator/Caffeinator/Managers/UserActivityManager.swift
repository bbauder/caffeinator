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

    typealias DeclareActivity = (inout IOPMAssertionID) -> Void

    var isEnabled: Bool = false

    private let declareActivity: DeclareActivity
    private let interval: Duration
    private(set) var task: Task<Void, Never>?

    init(declareActivity: @escaping DeclareActivity = UserActivityManager.iokitDeclare,
         interval: Duration = .seconds(30)) {
        self.declareActivity = declareActivity
        self.interval = interval
    }

    func start() {
        stop()

        guard isEnabled else {
            return
        }

        let declare = declareActivity
        let tick = interval

        task = Task {
            var assertionID: IOPMAssertionID = 0

            while !Task.isCancelled {
                declare(&assertionID)
                try? await Task.sleep(for: tick)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    nonisolated static let iokitDeclare: DeclareActivity = { assertionID in
        IOPMAssertionDeclareUserActivity("Caffeinator user activity" as CFString,
                                         kIOPMUserActiveLocal,
                                         &assertionID)
    }
}
