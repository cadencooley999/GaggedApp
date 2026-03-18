//
//  BackgroundHelper.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/21/26.
//

import SwiftUI
import Foundation

final class BackgroundHelper {
    
    static let shared = BackgroundHelper()
    
    var appleHeaderBlur: some View {
        // 👇 visual-only blur layer
        Rectangle()
            .fill(.thinMaterial)
            .overlay(Color.theme.background.opacity(0.9))
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .black.opacity(0.9), location: 0.35),
                        .init(color: .black.opacity(0.7), location: 0.55),
                        .init(color: .black.opacity(0.3), location: 0.75),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 160)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)   // 👈 SAFE now
//        Rectangle()
//            .fill(.ultraThinMaterial)
//            .overlay(Color.theme.background.opacity(0.5))
//            .mask(
//                LinearGradient(
//                    stops: [
//                        .init(color: .black.opacity(0.9), location: 0.0),
//                        .init(color: .black.opacity(0.9), location: 0.15),
//                        .init(color: .black.opacity(0.90), location: 0.55),
//                        .init(color: .black.opacity(0.75), location: 0.6),
//                        .init(color: .black.opacity(0.30), location: 0.7),
//                        .init(color: .black.opacity(0.2), location: 0.85),
//                        .init(color: .black.opacity(0.1), location: 0.9),
//                        .init(color: .black.opacity(0), location: 1.0)
//                    ],
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//            )
//            .ignoresSafeArea(edges: .top)
//            .allowsHitTesting(false)
    }
    

    
    var appleFooterBlur: some View {
        Rectangle()
            .fill(.thinMaterial)
            .overlay(Color.theme.background.opacity(0.9))
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .black.opacity(0.9), location: 0.35),
                        .init(color: .black.opacity(0.7), location: 0.55),
                        .init(color: .black.opacity(0.3), location: 0.75),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: 160)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
    }

}



