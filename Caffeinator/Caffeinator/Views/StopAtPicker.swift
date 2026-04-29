//
//  StopAtPicker.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import SwiftUI

struct StopAtPickerView: View {
    @ObservedObject var wakeManager: WakeAssertionManager
    @State private var selectedTime: Date
    var onDismiss: () -> Void

    init(wakeManager: WakeAssertionManager, onDismiss: @escaping () -> Void) {
        self.wakeManager = wakeManager
        self.onDismiss = onDismiss
        self._selectedTime = State(initialValue: Self.nextHalfHour())
    }

    private var formattedSelectedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }

    var body: some View {
        VStack(spacing: 8) {
            DatePicker(L.keepAwakeUntilLabel, selection: $selectedTime, displayedComponents: .hourAndMinute)

            Text(L.endsAt(formattedSelectedTime))
                .font(FontPalette.caption)
                .foregroundStyle(.secondary)

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
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 260)
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
