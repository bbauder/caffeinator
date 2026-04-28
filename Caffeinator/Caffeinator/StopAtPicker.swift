//
//  StopAtPicker.swift
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
        dismiss()
        Task {
            NSApp.activate()
            guard let button = Self.findStatusItemButton() else { return }

            let pickerView = StopAtPickerView(wakeManager: wakeManager) { [weak self] in
                self?.dismiss()
            }

            let popover = NSPopover()
            popover.contentSize = NSSize(width: 260, height: 120)
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

struct StopAtPickerView: View {
    @ObservedObject var wakeManager: WakeAssertionManager
    @State private var selectedTime: Date
    var onDismiss: () -> Void

    init(wakeManager: WakeAssertionManager, onDismiss: @escaping () -> Void) {
        self.wakeManager = wakeManager
        self.onDismiss = onDismiss
        self._selectedTime = State(initialValue: Self.nextHalfHour())
    }

    var body: some View {
        VStack(spacing: 12) {
            DatePicker(L.keepAwakeUntilLabel, selection: $selectedTime, displayedComponents: .hourAndMinute)
            HStack {
                Button(L.cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(L.start) {
                    wakeManager.activate(until: selectedTime)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 240)
    }

    static func nextHalfHour(from date: Date = .now) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        if minute < 30 {
            components.minute = 30
        } else {
            components.minute = 0
            components.hour = (components.hour ?? 0) + 1
        }
        return calendar.date(from: components) ?? date
    }
}
