//
//  WatchProcessesRow.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import SwiftUI

struct WatchProcessesRow: View {
    let process: WatchedProcess
    let isWatched: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let icon = process.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }

            Text(process.name)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            if isWatched {
                Image(systemName: "eye.fill")   // "checkmark.circle.fill" is a neutral option
                    .foregroundStyle(.tint)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            isWatched ? onRemove() : onAdd()
        }
    }
}
