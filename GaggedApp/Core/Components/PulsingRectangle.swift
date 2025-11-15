//
//  PulsingRectangle.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/24/25.
//


import SwiftUI

struct PulsingRectangle: View {
    @State private var fade = false
    let duration: Double

    var body: some View {
        Rectangle()
            .fill(Color.theme.lightGray)
            .opacity(fade ? 0.4 : 0.8) // animate between these values
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: fade
            )
            .background(Color.theme.background)
            .onAppear {
                fade.toggle() // start the animation
            }
            
    }
}
