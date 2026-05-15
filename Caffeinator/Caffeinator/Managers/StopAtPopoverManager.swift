//
//  StopAtPopoverManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import AppKit
import SwiftUI

@MainActor
final class StopAtPopoverManager {

    static let shared = StopAtPopoverManager()
    private var popover: NSPopover?

    func show(wakeManager: WakeAssertionManager) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }

        guard let button = Self.findStatusItemButton() else {
            return
        }

        let pickerView = StopAtPickerView(wakeManager: wakeManager) { [weak self] in
            self?.dismiss()
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 120)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: pickerView)
        self.popover = popover

        DispatchQueue.main.async {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }
    }

    func dismiss() {
        popover?.close()
        popover = nil
    }

    private static func findStatusItemButton() -> NSStatusBarButton? {
        for window in NSApp.windows {
            if let button = findButton(in: window.contentView) {
                return button
            }
        }
        return nil
    }

    private static func findButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view else {
            return nil
        }

        if let button = view as? NSStatusBarButton {
            return button
        }

        for subview in view.subviews {
            if let button = findButton(in: subview) {
                return button
            }
        }

        return nil
    }
}
