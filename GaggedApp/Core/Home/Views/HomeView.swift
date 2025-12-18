//
//  ContentView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import SwiftUI

struct HomeView: View {
    
    func safeArea() -> UIEdgeInsets {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first
        else { return .zero }

        return window.safeAreaInsets
    }
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @Binding var hideTabBar: Bool
    @Binding var showPostView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var selectedTab: TabBarItem
    
    @State var scrollOffset = CGPoint.zero
    
    var postAnimation: Namespace.ID
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
//            Image("AppImage")
//                .resizable()
//                .frame(width: 300)
//                .frame(height: 300)
            VStack(spacing: 0) {
                ScrollView(showsIndicators: true) {
                        VStack(spacing: 0) {
                            postSection
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .transition(.opacity)
                        }
                        .padding(.top, 60 + safeArea().top)
                        .padding(.bottom, 64)
                }
                .refreshable {
                    Task {
                        try await homeViewModel.fetchMorePosts(cities: locationManager.citiesInRange)
                    }
                }
                .onScrollPhaseChange({ oldPhase, newPhase, context in
                    let newOffset = context.geometry.contentOffset
                    if newOffset.y < scrollOffset.y {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hideTabBar = false
                        }
                    }
                    else if newOffset.y > scrollOffset.y && !(newOffset.y <= 10) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hideTabBar = true
                        }
                    }
                    scrollOffset = newOffset
                })
                .ignoresSafeArea()
            }
//            VStack(spacing: 0) {
//                VStack(spacing: 0){
//                    header
//                        .frame(height: 55)
//                    Divider()
//                }
//                .background(.thinMaterial)
//                Spacer()
//            }
            if homeViewModel.isLoading {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    ProgressView()
                }
            }
        }
//        .gesture(
//            DragGesture()
//                .onEnded { value in
//                    if value.translation.width < -80 {
//                        selectedTab = TabBarItem(iconName: "EventsIcon", title: "Events")
//                        hideTabBar = false
//                    }
//                    if value.translation.width > 80 {
//                        selectedTab = TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard")
//                        hideTabBar = false
//                    }
//                }
//        )
        .task {
            Task {
                print(homeViewModel.hasLoaded)
                print("HOME TASK RUN")
                await locationManager.requestLocationIfNeeded(execute: !homeViewModel.hasLoaded)
                try await homeViewModel.fetchPostsIfNeeded(cities: locationManager.citiesInRange)
                homeViewModel.hasLoaded = true
            }
        }
    }
    
    var postSection: some View {
        HStack {
            ForEach(0..<homeViewModel.columns) { x in
                VStack {
                    if homeViewModel.postMatrix.indices.contains(x) {
                        if !homeViewModel.postMatrix[x].isEmpty {
                            ForEach(homeViewModel.postMatrix[x], id: \.self) { post in
                                MiniPostView(post: post, width: nil)
                                    .id("\(post.id)-\(post.upvotes)-\(post.downvotes)")
                                    .contentShape(Rectangle())
                                    .transition(.opacity)
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
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    

}


