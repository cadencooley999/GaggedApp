//
//  LeaderView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/9/25.
//

import SwiftUI

struct LeaderView: View {
    
    @EnvironmentObject var leaderViewModel: LeaderViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windowSize: WindowSize
    
    @Binding var showPostView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var selectedTab: TabBarItem
    
    @State var thisWeekIndex: Int = 0
    @State var allUpIndex: Int = 0
    @State var allDownIndex: Int = 0
    
    var body: some View {
        ZStack {
            Background()
                .frame(maxWidth: windowSize.size.width, maxHeight: windowSize.size.height)
            ScrollView(showsIndicators: false){
                VStack (spacing: 24){
                    if leaderViewModel.thisWeekUp.count > 0 {
                        TopUpThisWeek
                    }
                    if leaderViewModel.allTimeUp.count > 0 {
                        TopUpAllTime
                    }
                    if leaderViewModel.allTimeDown.count > 0 {
                        MostDownAllTime
                    }
                    if leaderViewModel.isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    }
                }
                .padding(.top, 84)
                .padding(.bottom, 64)
            }

            .refreshable {
                Task {
                    try await leaderViewModel.fetchMoreLeaderboards(cities: locationManager.citiesInRange)
                }
            }
        }
//        .gesture(
//            DragGesture()
//                .onEnded { value in
//                    if value.translation.width < -80 { // left swipe
//                        selectedTab = TabBarItem(iconName: "HomeIcon", title: "Home")
//                    }
//                }
//        )
        .task {
            Task {
                try await leaderViewModel.fetchLeaderboardsIfNeeded(cities: locationManager.citiesInRange)
            }
        }
    }
    
    var TopUpThisWeek: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill").foregroundStyle(Color.theme.darkBlue)
                    Text("On Fire This Week")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(leaderViewModel.thisWeekUp.enumerated()), id: \.offset) { idx, post in
                        VStack(spacing: 8) {
                            MiniPostView(post: post, width: 180, stroked: nil)
                                .contentShape(Rectangle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                                .transition(.opacity)
                                .onTapGesture {
                                    selectedPost = leaderViewModel.thisWeekUp[idx]
                                    postViewModel.setPost(postSelection: leaderViewModel.thisWeekUp[idx])
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    Task {
                                        postViewModel.commentsIsLoading = true
                                        try await postViewModel.fetchComments()
                                        postViewModel.commentsIsLoading = false
                                    }
                                }
                            // Per-item stat under each mini post
                            if idx < leaderViewModel.weekStats.count {
                                HStack(spacing: 6) {
                                    Text("+ \(leaderViewModel.weekStats[idx])")
                                    Image(systemName: "arrow.up")
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.green)
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 180)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal)
            }
        }
    }
    
    var TopUpAllTime: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundStyle(Color.theme.darkBlue)
                    Text("Hall of Fame")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(leaderViewModel.allTimeUp.enumerated()), id: \.offset) { idx, post in
                        VStack(spacing: 8) {
                            MiniPostView(post: post, width: 180, stroked: nil)
                                .contentShape(Rectangle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                                .transition(.opacity)
                                .onTapGesture {
                                    selectedPost = post
                                    postViewModel.setPost(postSelection: post)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    Task {
                                        postViewModel.commentsIsLoading = true
                                        try await postViewModel.fetchComments()
                                        postViewModel.commentsIsLoading = false
                                    }
                                }
                        }
                        .frame(width: 180)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal)
            }
        }
    }
    
    var MostDownAllTime: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(Color.theme.darkBlue)
                    Text("Rogues Gallery")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(leaderViewModel.allTimeDown.enumerated()), id: \.offset) { idx, post in
                        VStack(spacing: 8) {
                            MiniPostView(post: post, width: 180, stroked: nil)
                                .contentShape(Rectangle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                                .transition(.opacity)
                                .onTapGesture {
                                    selectedPost = post
                                    postViewModel.setPost(postSelection: post)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    Task {
                                        postViewModel.commentsIsLoading = true
                                        try await postViewModel.fetchComments()
                                        postViewModel.commentsIsLoading = false
                                    }
                                }
                        }
                        .frame(width: 180)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal)
            }
        }
    }
}

