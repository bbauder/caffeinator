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
    private var positioningWindow: NSWindow?

    func show(wakeManager: WakeAssertionManager) {
        let mouseLocation = NSEvent.mouseLocation
        dismiss()
        Task {
            NSApp.activate()

            let pickerView = StopAtPickerView(wakeManager: wakeManager) { [weak self] in
                self?.dismiss()
            }

            let popover = NSPopover()
            popover.contentSize = NSSize(width: 260, height: 120)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: pickerView)

            let rect = NSRect(x: mouseLocation.x - 1, y: mouseLocation.y - 1, width: 2, height: 2)
            let window = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
            window.backgroundColor = .clear
            window.isReleasedWhenClosed = false
            window.level = .statusBar
            window.orderFront(nil)

            popover.show(relativeTo: window.contentView!.bounds, of: window.contentView!, preferredEdge: .minY)

            self.popover = popover
            self.positioningWindow = window
        }
    }

    func dismiss() {
        popover?.close()
        positioningWindow?.close()
        popover = nil
        positioningWindow = nil
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
            DatePicker("Stop at:", selection: $selectedTime, displayedComponents: .hourAndMinute)
            HStack {
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Start") {
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
