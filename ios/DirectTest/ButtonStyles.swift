//
//  ButtonStyles.swift
//  DirectTest
//
//  Created by Adrian DeLeon on 21/8/25.
//

import SwiftUI

// Custom button style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
