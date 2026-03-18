//
//  Background.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/20/26.
//

import SwiftUI
import Foundation

struct Background: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)

            Image("noise")
                .resizable()
                .scaledToFit()
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [
                    Color.theme.background.opacity(0.06),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
