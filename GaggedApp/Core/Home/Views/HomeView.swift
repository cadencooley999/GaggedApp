//
//  ContentView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    
    @Binding var hideTabBar: Bool
    @Binding var showPostView: Bool
    @Binding var showSearchView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var selectedTab: TabBarItem
    
    @State var scrollOffset = CGPoint.zero
    @State var blurHeader: Bool = false
    
    var postAnimation: Namespace.ID
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) {
                        postSection
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                    }
                    .padding(.top, 120)
                    .padding(.bottom, 64)
                }
                .refreshable {
                    Task {
                        try await homeViewModel.fetchMorePosts()
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
                    if newPhase.isScrolling {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            blurHeader = true
                        }
                    }
                    if newPhase == .decelerating  {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                blurHeader = false
                            }
                        })
                    }
                    if newPhase == .idle {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            blurHeader = false
                        }
                    }
                })
                .ignoresSafeArea()
            }
            VStack(spacing: 0) {
                header
                    .frame(height: 55)
                    .background(Color.theme.background)
                    .opacity(blurHeader ? 0.9 : 1)
                Divider()
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -80 {
                        selectedTab = TabBarItem(iconName: "EventsIcon", title: "Events")
                        hideTabBar = false
                    }
                    if value.translation.width > 80 {
                        selectedTab = TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard")
                        hideTabBar = false
                    }
                }
        )
        .task {
            Task {
                try await homeViewModel.fetchPostsIfNeeded()
            }
        }
    }
    var header: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                Image(systemName: "sharedwithyou")
                    .font(.title2)
                Text("Gagged")
                    .font(.title)
                    .padding(.horizontal, 8)
                HStack {
                    Text("San Marcos")
                        .font(.subheadline)
                    Image(systemName: "mappin")
                        .foregroundStyle(Color.theme.darkBlue)
                }
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.clear)
                        .stroke(Color.theme.darkBlue, lineWidth: 1)
                )
                .padding(.horizontal)
                Spacer()
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            hideTabBar = true
                            showSearchView = true
                            
                        }
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    var postSection: some View {
        HStack {
            ForEach(0..<homeViewModel.columns) { x in
                VStack {
                    if homeViewModel.postMatrix.indices.contains(x) {
                        if !homeViewModel.postMatrix[x].isEmpty {
                            ForEach(homeViewModel.postMatrix[x]) { post in
                                MiniPostView(post: post, width: nil)
                                    .contentShape(Rectangle())
                                    .matchedGeometryEffect(id: post.id, in: postAnimation)
                                    .onTapGesture {
                                        print("Little Post Tapped")
                                        selectedPost = post
                                        postViewModel.setPost(postSelection: post)
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
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    

}

#Preview {
    @Namespace var dummy
    
    HomeView(hideTabBar: .constant(false), showPostView: .constant(false), showSearchView: .constant(false), selectedPost: .constant(nil), selectedTab: .constant(TabBarItem(iconName: "HomeIcon", title: "Home")), postAnimation:  dummy)
        .environmentObject(HomeViewModel.previewModel())
}
