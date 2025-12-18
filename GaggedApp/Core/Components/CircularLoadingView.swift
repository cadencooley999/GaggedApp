//
//  CircularLoadingView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/16/25.
//

import SwiftUI


struct CircularLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.7)
            .stroke(
                Color.theme.white,
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
