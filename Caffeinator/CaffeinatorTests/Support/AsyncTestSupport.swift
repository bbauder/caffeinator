//
//  AsyncTestSupport.swift
//  CaffeinatorTests
//

import Foundation
import XCTest

/// Lets Combine `receive(on: RunLoop.main)` subscriptions and other scheduled
/// main-actor work get a chance to run.
@MainActor
func pumpMainRunLoop(times: Int = 3) async {
    for _ in 0..<times {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(5))
    }
}

extension XCTestCase {

    /// Awaits up to `timeout` for `condition` to become true.
    /// Polls every 10ms.
    @MainActor
    func waitFor(_ condition: @autoclosure () -> Bool,
                 timeout: TimeInterval = 1.0,
                 file: StaticString = #file,
                 line: UInt = #line) async {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition() && Date() < deadline {
            await pumpMainRunLoop(times: 1)
        }

        if !condition() {
            XCTFail("Condition not met within \(timeout)s", file: file, line: line)
        }
    }
}
