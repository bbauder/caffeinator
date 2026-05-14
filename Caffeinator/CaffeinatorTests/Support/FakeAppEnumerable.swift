//
//  FakeAppEnumerable.swift
//  CaffeinatorTests
//

import AppKit
@testable import Caffeinator

struct FakeApp: AppEnumerable {

    var processIdentifier: pid_t
    var activationPolicy: NSApplication.ActivationPolicy = .regular
    var isTerminated: Bool = false
    var executableURL: URL? = URL(fileURLWithPath: "/Applications/FakeApp.app/Contents/MacOS/FakeApp")
    var localizedName: String? = "FakeApp"
    var bundleIdentifier: String? = "com.example.fake"
    var icon: NSImage? = nil

    static func make(pid: pid_t,
                     name: String? = "FakeApp",
                     policy: NSApplication.ActivationPolicy = .regular,
                     terminated: Bool = false,
                     executableURL: URL? = URL(fileURLWithPath: "/Applications/FakeApp.app/Contents/MacOS/FakeApp"),
                     bundleIdentifier: String? = "com.example.fake") -> FakeApp {
        FakeApp(processIdentifier: pid,
                activationPolicy: policy,
                isTerminated: terminated,
                executableURL: executableURL,
                localizedName: name,
                bundleIdentifier: bundleIdentifier,
                icon: nil)
    }
}
