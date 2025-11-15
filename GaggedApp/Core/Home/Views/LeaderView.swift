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
    
    @Binding var hideTabBar: Bool
    @Binding var showPostView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var selectedTab: TabBarItem
    
    @State var thisWeekIndex: Int = 0
    @State var allUpIndex: Int = 0
    @State var allDownIndex: Int = 0
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea(edges: .all)
            ScrollView {
                VStack (spacing: 380){
                    if leaderViewModel.thisWeekUp.count > 0 {
                        TopUpThisWeek
                    }
                    TopUpAllTime
                    MostDownAllTime
                }
                .padding(.top, 82)
                .padding(.horizontal)
                .padding(.bottom, 420)
            }

            .refreshable {
                Task {
                    try await leaderViewModel.fetchMoreLeaderboards()
                }
            }
            VStack(spacing: 0){
                header
                    .frame(height: 55)
                    .background(Color.theme.background)
                Divider()
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -80 { // left swipe
                        selectedTab = TabBarItem(iconName: "HomeIcon", title: "Home")
                    }
                }
        )
        .task {
            Task {
                try await leaderViewModel.fetchLeaderboardsIfNeeded()
            }
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                Image(systemName: "chevron.down")
                    .font(.title2)
                Text("Leaderboards")
                    .font(.title2)
                    .padding(.horizontal, 4)
                Text("San Marcos, TX")
                    .italic()
                    .font(.title2)
                    .padding(.horizontal, 8)
                    .foregroundStyle(Color.theme.darkBlue)
                Spacer()
                Image(systemName: "magnifyingglass")
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    var TopUpThisWeek: some View {
        VStack {
            Text("On Fire This Week 🔥")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            GeometryReader {
                let width = $0.size.width
                HStack {
                    LoopingStack(maxTranslationWidth: width, thisWeekIndex: $thisWeekIndex) {
                        ForEach(leaderViewModel.thisWeekUp) { post in
                                MiniPostView(post: post, width: 200)
                        }
                    }
                    .onTapGesture {
                        print("Little Post Tapped")
                        selectedPost = leaderViewModel.thisWeekUp[thisWeekIndex]
                        postViewModel.setPost(postSelection: leaderViewModel.thisWeekUp[thisWeekIndex])
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPostView = true
                            hideTabBar = true
                        }
                        Task {
                            postViewModel.commentsIsLoading = true
                            try await postViewModel.fetchComments()
                            postViewModel.commentsIsLoading = false
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    HStack {
                        Text("+ \(leaderViewModel.getUpStat(index: thisWeekIndex, list: .thisWeekUp) ?? 0)")
                        Image(systemName: "arrow.up")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    var TopUpAllTime: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Most Upvoted All Time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            GeometryReader {
                let width = $0.size.width
                HStack {
                    LoopingStack(maxTranslationWidth: width, thisWeekIndex: $allUpIndex) {
                        ForEach(leaderViewModel.allTimeUp) { post in
                                MiniPostView(post: post, width: 200)
                        }
                    }
                    .onTapGesture {
                        print("Little Post Tapped")
                        selectedPost = leaderViewModel.allTimeUp[allUpIndex]
                        postViewModel.setPost(postSelection: leaderViewModel.allTimeUp[allUpIndex])
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPostView = true
                            hideTabBar = true
                        }
                        Task {
                            postViewModel.commentsIsLoading = true
                            try await postViewModel.fetchComments()
                            postViewModel.commentsIsLoading = false
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    HStack {
                        Text("+ \(leaderViewModel.getUpStat(index: allUpIndex, list: .allTimeUp) ?? 0)")
                        Image(systemName: "arrow.up")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    var MostDownAllTime: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Most Downvoted All Time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            GeometryReader {
                let width = $0.size.width
                HStack {
                    LoopingStack(maxTranslationWidth: width, thisWeekIndex: $allDownIndex) {
                        ForEach(leaderViewModel.allTimeDown) { post in
                                MiniPostView(post: post, width: 200)
                        }
                    }
                    .onTapGesture {
                        print("Little Post Tapped")
                        selectedPost = leaderViewModel.allTimeDown[allDownIndex]
                        postViewModel.setPost(postSelection: leaderViewModel.allTimeDown[allDownIndex])
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPostView = true
                            hideTabBar = true
                        }
                        Task {
                            postViewModel.commentsIsLoading = true
                            try await postViewModel.fetchComments()
                            postViewModel.commentsIsLoading = false
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    HStack {
                        Text("+ \(leaderViewModel.getUpStat(index: allDownIndex, list: .allTimeDown) ?? 0)")
                        Image(systemName: "arrow.down")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

#Preview {
    LeaderView(hideTabBar: .constant(false), showPostView: .constant(false), selectedPost: .constant(nil), selectedTab: .constant(TabBarItem(iconName: "LeaderIcon", title: "LeaderBoards")))
}
