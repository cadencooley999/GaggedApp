//
//  PollsView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/23/25.
//

import SwiftUI

struct PollsView: View {
    
    @Binding var selectedTab: TabBarItem
    @Binding var hideTabBar: Bool
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Text("WHATS UPPP")
                        .padding(.top, 50)
                }
            }
        }
//        .gesture(
//            DragGesture()
//                .onEnded { value in
//                    if value.translation.width > 80 {
//                        selectedTab = TabBarItem(iconName: "EventsIcon", title: "Events")
//                    }
//                }
//        )
    }
}
