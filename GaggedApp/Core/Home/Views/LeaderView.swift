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
                VStack (spacing: 0){
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
                .padding(.top, 116)
                .padding(.horizontal)
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
        VStack {
            Text("On Fire This Week 🔥")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(leaderViewModel.thisWeekUp) { post in
                        VStack {
                            MiniPostView(post: post, width: 220, stroked: nil)
                                .onTapGesture {
                                    print("Little Post Tapped")
                                    selectedPost = leaderViewModel.thisWeekUp[thisWeekIndex]
                                    postViewModel.setPost(postSelection: leaderViewModel.thisWeekUp[thisWeekIndex])
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    Task {
                                        postViewModel.commentsIsLoading = true
                                        try await postViewModel.fetchComments()
                                        postViewModel.commentsIsLoading = false
                                    }
                                }
                            HStack {
                                Text("+ \(leaderViewModel.getUpStat(index: thisWeekIndex, list: .thisWeekUp) ?? 0)")
                                Image(systemName: "arrow.up")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
//            GeometryReader {
//                let width = $0.size.width
//                HStack {
//                    LoopingStack(maxTranslationWidth: width, thisWeekIndex: $thisWeekIndex) {
//                        ForEach(leaderViewModel.thisWeekUp) { post in
//                                MiniPostView(post: post, width: 220)
//                        }
//                    }
//                    .onTapGesture {
//                        print("Little Post Tapped")
//                        selectedPost = leaderViewModel.thisWeekUp[thisWeekIndex]
//                        postViewModel.setPost(postSelection: leaderViewModel.thisWeekUp[thisWeekIndex])
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showPostView = true
//                        }
//                        Task {
//                            postViewModel.commentsIsLoading = true
//                            try await postViewModel.fetchComments()
//                            postViewModel.commentsIsLoading = false
//                        }
//                    }
//                    .contentShape(Rectangle())
//                    .padding(.horizontal)
//                    HStack {
//                        Text("+ \(leaderViewModel.getUpStat(index: thisWeekIndex, list: .thisWeekUp) ?? 0)")
//                        Image(systemName: "arrow.up")
//                            .fontWeight(.bold)
//                            .foregroundStyle(Color.green)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//            }
        }
    }
    
    var TopUpAllTime: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Most Upvoted All Time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(leaderViewModel.allTimeUp) { post in
                        VStack {
                            MiniPostView(post: post, width: 220, stroked: nil)
                                .onTapGesture {
                                    print("Little Post Tapped")
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
                            HStack {
                                Text("+ \(leaderViewModel.getUpStat(index: thisWeekIndex, list: .thisWeekUp) ?? 0)")
                                Image(systemName: "arrow.up")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    var MostDownAllTime: some View {
        VStack(alignment: .leading, spacing: 8){
            Text("Most Downvoted All Time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(leaderViewModel.allTimeDown) { post in
                        VStack {
                            MiniPostView(post: post, width: 220, stroked: nil)
                                .onTapGesture {
                                    print("Little Post Tapped")
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
                            HStack {
                                Text("+ \(leaderViewModel.getUpStat(index: thisWeekIndex, list: .thisWeekUp) ?? 0)")
                                Image(systemName: "arrow.down")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
//            GeometryReader {
//                let width = $0.size.width
//                HStack {
//                    LoopingStack(maxTranslationWidth: width, thisWeekIndex: $allDownIndex) {
//                        ForEach(leaderViewModel.allTimeDown) { post in
//                                MiniPostView(post: post, width: 220)
//                        }
//                    }
//                    .onTapGesture {
//                        print("Little Post Tapped")
//                        selectedPost = leaderViewModel.allTimeDown[allDownIndex]
//                        postViewModel.setPost(postSelection: leaderViewModel.allTimeDown[allDownIndex])
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showPostView = true
//                        }
//                        Task {
//                            postViewModel.commentsIsLoading = true
//                            try await postViewModel.fetchComments()
//                            postViewModel.commentsIsLoading = false
//                        }
//                    }
//                    .contentShape(Rectangle())
//                    .padding(.horizontal)
//                    HStack {
//                        Text("+ \(leaderViewModel.getUpStat(index: allDownIndex, list: .allTimeDown) ?? 0)")
//                        Image(systemName: "arrow.down")
//                            .fontWeight(.bold)
//                            .foregroundStyle(Color.red)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//            }
        }
    }
}
