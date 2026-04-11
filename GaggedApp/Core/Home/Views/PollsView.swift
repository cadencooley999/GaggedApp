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
    @Binding var selectedPoll: PollWithOptions?
    @Binding var showPollView: Bool
    @Binding var showReportView: Bool
    @Binding var preReportInfo: preReportModel?
    
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
                if pollsViewModel.polls.count == 0 && pollsViewModel.hasLoaded{
                    Text("No polls available for this location.")
                        .font(.caption)
                        .foregroundStyle(Color.theme.trashcanGray)
                        .padding(.top, 196 + safeArea().top)
                }
                else {
                    VStack(spacing: 0) {
                        LazyVGrid(columns: pollsViewModel.columns, spacing: 0) {
                            ForEach(pollsViewModel.polls, id: \.id) { poll in
                                PollCard(screenType: .pollsFeed, poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo)
                                    .shadow(color: .black.opacity(0.12), radius: 8, y: 6)
                                    .transition(.opacity)
                                    .onTapGesture {
                                        selectedPoll = poll
                                        pollsViewModel.poll = poll
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showPollView = true
                                        }
                                    }
                                    .onAppear {
                                        if poll.id == pollsViewModel.polls.last?.id {
                                            Task {
                                                try await pollsViewModel.getMorePolls(cityIds: locationManager.citiesInRange)
                                            }
                                        }
                                    }
                                    .padding(.bottom)
                            }
                        }
                        .transition(.opacity)
                        .padding(.top, windowSize.size.width > 700 ? safeArea().top + 48 : safeArea().top + 16)
                        .padding(.horizontal)
                        if pollsViewModel.isLoading {
                            ProgressView()
                                .padding(.top, 64)
                        }
                    }
                    .padding(.bottom, pollsViewModel.hasMore ? 800 : 104)
                }
            }
            .refreshable {
                Task {
                    try await pollsViewModel.getInitialPolls(cityIds: locationManager.citiesInRange)
                }
            }
            
        }
        .task {
            print("poll task run")
            if windowSize.size.width > 700 {
                pollsViewModel.columns = [GridItem(), GridItem()]
            }
            Task {
                if !pollsViewModel.hasLoaded {
                    try await pollsViewModel.getInitialPolls(cityIds: locationManager.citiesInRange)
                }
                pollsViewModel.hasLoaded = true
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

