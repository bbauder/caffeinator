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
