//
//  MultiLineTextViewModifier.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/5/26.
//


import SwiftUI

private struct MultiLineTextViewModifier: ViewModifier {

    let multiLineTextAlignment: TextAlignment
    let lineSpacing: CGFloat

    // .fixedSize() determines whether the view accepts or rejects the parent’s size proposal,
    // not about whether the view is fixed or flexible in either dimension.
    // In other words, my intent is:
    //     - Horizontal: Constrain me (wrap text)
    //     - Vertical: Let me grow (get taller as text wraps)
    // But .fixedSize() expresses:
    //     - Horizontal: Don't escape the parent
    //     - Vertical: Escape the parent
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(multiLineTextAlignment)
            .lineSpacing(lineSpacing)
    }
}

extension View {

    @warn_unqualified_access
    public func multiLineTextStyle(multiLineTextAlignment: TextAlignment = .center,
                                   lineSpacing: CGFloat = 2) -> some View {
        return modifier(MultiLineTextViewModifier(multiLineTextAlignment: multiLineTextAlignment,
                                                  lineSpacing: lineSpacing))
    }
}
