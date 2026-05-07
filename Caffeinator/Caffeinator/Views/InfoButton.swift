//
//  InfoButton.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import SwiftUI

struct InfoButton: View {
    var popoverText: String?

    @State private var showPopover = false
    @State private var isHovering = false

    var body: some View {
        if let popoverText {
            Button {
                showPopover.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .opacity(isHovering ? 0.95 : 0.75)
                    .scaleEffect(isHovering ? 1.25 : 1.0)
                    .frame(width: 16, height: 16, alignment: .center)
                    .animation(.easeOut(duration: 0.12), value: isHovering)
            }
            .buttonStyle(.borderless)
            .onHover { isHovering = $0 }
            .popover(isPresented: $showPopover) {
                Text(popoverText)
                    .padding()
                    .frame(maxWidth: 260, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 16, alignment: .center)
        }
    }
}
