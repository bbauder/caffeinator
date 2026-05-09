//
//  WatchProcessesPopoverManager.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import AppKit
import SwiftUI

@MainActor
final class WatchProcessesPopoverManager: NSObject, NSPopoverDelegate {

    static let shared = WatchProcessesPopoverManager()
    private var popover: NSPopover?

    func show(viewModel: WatchProcessesViewModel) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }

        guard let button = Self.findStatusItemButton() else {
            return
        }

        viewModel.beginPendingSelection()

        let popoverView = WatchProcessesPopover(viewModel: viewModel) { [weak self] in
            self?.dismiss()
        }

        let popover = NSPopover()
        popover.delegate = self
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: popoverView)
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

    nonisolated func popoverDidClose(_ notification: Notification) {
        MainActor.assumeIsolated {
            popover = nil
        }
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
