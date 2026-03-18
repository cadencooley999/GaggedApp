//
//  CustomRefreshable.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/23/26.
//
import SwiftUI

struct CustomRefreshable: ViewModifier {
    
    let threshold: CGFloat
    let action: () async -> Void
    
    @State private var isRefreshing = false
    @State private var readyToTrigger = true
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: RefreshOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                }
                .frame(height: 0)
            }
            .onPreferenceChange(RefreshOffsetKey.self) { offset in
                handleOffset(offset)
            }
    }
    
    private func handleOffset(_ offset: CGFloat) {
        if offset < 10 && readyToTrigger == false {
            print("less")
            readyToTrigger = true
        }
        guard readyToTrigger, !isRefreshing else { return }
        
        if offset > threshold {
            readyToTrigger = false
            isRefreshing = true
            
            Task {
                await action()
                isRefreshing = false
            }
        }
    }
}

private struct RefreshOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func customRefreshable(
        threshold: CGFloat = 125,
        action: @escaping () async -> Void
    ) -> some View {
        self.modifier(CustomRefreshable(threshold: threshold, action: action))
    }
}
