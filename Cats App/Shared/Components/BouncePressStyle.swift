//
//  BouncePressStyle.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 19/10/25.
//

import SwiftUI

struct BouncePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.10 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.25),
                   value: configuration.isPressed)
    }
}
