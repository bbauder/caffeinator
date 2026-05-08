//
//  WatchProcessesPopoverManager.swift
//  Caffeinator
//

import AppKit
import SwiftUI

@MainActor
final class WatchProcessesPopoverManager {
    static let shared = WatchProcessesPopoverManager()
    private var popover: NSPopover?

    func show(viewModel: WatchProcessesViewModel) {
        dismiss()

        Task {
            NSApp.activate()
            guard let button = Self.findStatusItemButton() else {
                return
            }

            let popoverView = WatchProcessesPopover(viewModel: viewModel) { [weak self] in
                self?.dismiss()
            }

            let popover = NSPopover()
            popover.contentSize = NSSize(width: 320, height: 420)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: popoverView)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)

            self.popover = popover
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
