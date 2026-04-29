//
//  CustomDurationPicker.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/28/26.
//

import SwiftUI

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
                .font(FontPalette.caption)
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
