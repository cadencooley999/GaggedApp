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
    
    @AppStorage("userId") var userId = ""
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var windowSize: WindowSize
    
    @Binding var hideTabBar: Bool
    @Binding var showPostView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var selectedTab: TabBarItem
    @Binding var postScreenType: ScreenType
    
    @State var scrollOffset = CGPoint.zero
    
    var postAnimation: Namespace.ID
    
    var body: some View {
        ZStack {
            Background()
                .frame(width: windowSize.size.width, height: windowSize.size.height)
//            Image("AppImage")
//                .resizable()
//                .frame(width: 300)
//                .frame(height: 300)
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 0.1)
                            .id("top")
                            VStack(spacing: 0) {
                                postSection
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .transition(.opacity)
                                if homeViewModel.feedStore.loadedPosts.count == 0 && homeViewModel.hasLoaded{
                                    Text("No posts available for this location")
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.trashcanGray)
                                        .padding(.top, 160)
                                }
                                if homeViewModel.isLoading {
                                    ProgressView()
                                        .padding(.top, homeViewModel.feedStore.loadedPosts.count == 0 ? 128 : 64)
                                }
                            }
                            .padding(.top, 55 + safeArea().top)
                            .padding(.bottom, homeViewModel.hasMore ? 1000 : 104)
                    }
                    .onChange(of: homeViewModel.feedStore.loadedPosts.count) {
                        if homeViewModel.feedStore.loadedPosts.count == 0 {
                            proxy.scrollTo("top")
                        }
                    }
                    .refreshable {
                        print("refreshing")
                        Task {
                            await homeViewModel.loadInitialPostFeed(cityIds: locationManager.citiesInRange)
                        }
                    }
                    .ignoresSafeArea()
                }
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
            print("running home task")
            Task {
                if feedStore.hasLoadedBlocked == false {
                    print("fetching blocked")
                    try await feedStore.fetchBlockedLists(userId)
                }
                guard homeViewModel.hasLoaded == false else { return }
                if windowSize.size.width > 700 && homeViewModel.columns != 3 {
                    print(windowSize.size.width, "width")
                    homeViewModel.columns = 3
                    print(homeViewModel.columns, "columns")
                }
                let cities = try await locationManager.requestLocationIfNeeded(execute: !homeViewModel.hasLoaded)
                if cities.isEmpty {
                    await homeViewModel.loadInitialPostFeed(cityIds: locationManager.citiesInRange)
                    print("cities empty")
                }
                else {
                    await homeViewModel.loadInitialPostFeed(cityIds: cities)
                    print("cities not empty")
                }
                homeViewModel.hasLoaded = true
            }
        }
    }
    
    var postSection: some View {
        HStack {
            ForEach(Array(homeViewModel.postMatrix.indices), id: \.self) { x in
                VStack {
                    if homeViewModel.postMatrix.indices.contains(x) {
                        if !homeViewModel.postMatrix[x].isEmpty {
                            LazyVStack {
                                ForEach(homeViewModel.postMatrix[x], id: \.self) { post in
                                    MiniPostView(post: post, width: nil, stroked: nil)
//                                        .opacity(selectedPost?.id == post.id && showPostView ? 0 : 1)
                                        .id("\(post.id)-\(post.upvotes)-\(post.downvotes)")
                                        .contentShape(Rectangle())
                                        .shadow(color: .black.opacity(0.10), radius: 8, y: 6)
                                        .transition(.opacity)
                                        .onTapGesture {
                                            print("Little Post Tapped")
                                            selectedPost = post
                                            postViewModel.setPost(postSelection: post)
                                            postScreenType = .homeFeed
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showPostView = true
                                            }
                                            Task {
                                                postViewModel.commentsIsLoading = true
                                                print("home com fetch")
                                                try await postViewModel.loadInitialRootComments(blockedIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                                postViewModel.commentsIsLoading = false
                                            }
                                        }
                                        .onAppear {
                                            guard post.id == homeViewModel.feedStore.loadedPosts.last?.id else {return}
                                            Task {
                                                print("last post seen", post.id)
                                                await homeViewModel.loadMorePostFeed(cityIds: locationManager.citiesInRange)
                                            }
                                        }
                                        .transition(.opacity)
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
