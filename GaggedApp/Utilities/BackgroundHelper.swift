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
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.9), location: 0.0),
                        .init(color: .black.opacity(0.9), location: 0.15),
                        .init(color: .black.opacity(0.90), location: 0.55),
                        .init(color: .black.opacity(0.75), location: 0.7),
                        .init(color: .black.opacity(0.30), location: 0.8),
                        .init(color: .black.opacity(0.2), location: 0.85),
                        .init(color: .black.opacity(0.1), location: 0.9),
                        .init(color: .black.opacity(0), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }
    
    var appleFooterBlur: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.0), location: 0.0),
                        .init(color: .black.opacity(0.1), location: 0.1),
                        .init(color: .black.opacity(0.2), location: 0.15),
                        .init(color: .black.opacity(0.30), location: 0.2),
                        .init(color: .black.opacity(0.75), location: 0.3),
                        .init(color: .black.opacity(0.90), location: 0.45),
                        .init(color: .black.opacity(0.9), location: 0.85),
                        .init(color: .black.opacity(0.9), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
    }

}



