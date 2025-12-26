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
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(pollsViewModel.polls, id: \.poll.id) { poll in
                        PollCard(poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView)
                            .padding(.bottom)
                    }
                }
                .padding(.top, 55 + safeArea().top)
                .padding(.bottom, 72)
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
