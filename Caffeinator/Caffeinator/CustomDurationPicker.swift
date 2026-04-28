//
//  CustomDurationPicker.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import AppKit
import SwiftUI

@MainActor
final class CustomDurationPopoverManager {
    static let shared = CustomDurationPopoverManager()
    private var popover: NSPopover?

    func show(wakeManager: WakeAssertionManager) {
        dismiss()
        Task {
            NSApp.activate()
            guard let button = Self.findStatusItemButton() else { return }

            let pickerView = CustomDurationPickerView(wakeManager: wakeManager) { [weak self] in
                self?.dismiss()
            }

            let popover = NSPopover()
            popover.contentSize = NSSize(width: 260, height: 150)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: pickerView)
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
        guard let view else { return nil }
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

struct CustomDurationPickerView: View {
    @ObservedObject var wakeManager: WakeAssertionManager
    @State private var hours = 1
    @State private var minutes = 0
    var onDismiss: () -> Void

    private var duration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }

    private var endTime: String {
        let endDate = Date.now.addingTimeInterval(duration)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Stepper(L.hours(hours), value: $hours, in: 0...23)
                Stepper(L.minutes(minutes), value: $minutes, in: 0...59, step: 5)
            }

            Text(L.endsAt(endTime))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button(L.cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(L.start) {
                    let endDate = Date.now.addingTimeInterval(duration)
                    wakeManager.activate(until: endDate)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(duration == 0)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
