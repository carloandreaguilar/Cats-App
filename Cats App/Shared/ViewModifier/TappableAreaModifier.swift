//
//  TappableAreaModifier.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 18/10/25.
//

import SwiftUI

/// Adds tappable area without changing its spacing within a view. 
struct TappableAreaModifier: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(size)
            .contentShape(Rectangle())
            .background(Color.clear)
            .padding(-size)
    }
}

extension View {
    func extraTappableArea(_ size: CGFloat) -> some View {
        modifier(TappableAreaModifier(size: size))
    }
}
