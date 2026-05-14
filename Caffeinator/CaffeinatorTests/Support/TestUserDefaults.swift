//
//  TestUserDefaults.swift
//  CaffeinatorTests
//

import Foundation

enum TestUserDefaults {

    /// Returns a UserDefaults instance backed by a unique in-memory suite.
    /// Caller is responsible for removing the persistent domain when done
    /// (or just discarding — these suites do not pollute .standard).
    static func make(file: StaticString = #file, line: UInt = #line) -> UserDefaults {
        let suite = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
