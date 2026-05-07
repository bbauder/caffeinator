//
//  InfoButton.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/7/26.
//

import SwiftUI

struct InfoButton: View {
    var help: String?
    var popoverText: String?

    @State private var showPopover = false

    var body: some View {
        let icon = Image(systemName: "info.circle")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(width: 16, height: 16, alignment: .center)

        if let popoverText {
            Button {
                showPopover.toggle()
            } label: {
                icon
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showPopover) {
                Text(popoverText)
                    .padding()
                    .frame(maxWidth: 280)
            }
            .modifier(OptionalHelp(text: help))
        } else {
            icon
                .modifier(OptionalHelp(text: help))
        }
    }
}

private struct OptionalHelp: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text {
            content.help(text)
        } else {
            content
        }
    }
}
