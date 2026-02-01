//
//  PollsView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/23/25.
//

import SwiftUI

struct PollsView: View {
    
    func safeArea() -> UIEdgeInsets {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first
        else { return .zero }

        return window.safeAreaInsets
    }
    
    @Binding var selectedTab: TabBarItem
    @Binding var hideTabBar: Bool
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windowSize: WindowSize
    
    var body: some View {
        ZStack {
            Background()
                .frame(maxWidth: windowSize.size.width, maxHeight: windowSize.size.height)
//            Color.blue
//                .ignoresSafeArea()
//                .frame(width: windowSize.size.width, height: windowSize.size.height)
            ScrollView (showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(pollsViewModel.polls, id: \.poll.id) { poll in
                        PollCard(poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 6)
                            .padding(.bottom)
                    }
                }
                .padding(.top, safeArea().top + 16)
                .padding(.bottom, 72)
                .padding(.horizontal)
            }
            .refreshable {
                Task {
                    try await pollsViewModel.getMorePolls(cityIds: locationManager.citiesInRange)
                }
            }
            
            if pollsViewModel.isLoading {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .task {
            print("poll task run")
            Task {
                try await pollsViewModel.getPollsIfNeeded(cityIds: locationManager.citiesInRange)
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
