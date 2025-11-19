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
    @EnvironmentObject var locationManager: LocationManager
    
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
            Image("AppImage")
                .resizable()
                .frame(width: 300)
                .frame(height: 300)
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
                VStack(spacing: 0){
                    header
                        .frame(height: 55)
                        .opacity(blurHeader ? 0.7 : 1)
                    Divider()
                }
                .background(Color.theme.background.opacity(blurHeader ? 0.7 : 1))
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
                locationManager.requestLocation()
                try await homeViewModel.fetchPostsIfNeeded()
            }
        }
    }
    
    var header: some View {
        HStack(spacing: 16) {
        // Left: App name only (Logo removed as requested)
            Text("Gagged")
                .font(.title2.bold())
                .foregroundColor(Color.theme.darkBlue)
            
            Spacer()
            
            HStack(spacing: 0){
                Text(locationManager.cityName ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(Color.theme.darkBlue)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.theme.lightBlue.opacity(0.2))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
                
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(Color.theme.darkBlue)
                        .padding(8) // Gives a good tap target size
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                     hideTabBar = true
                     showSearchView = true
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(Color.theme.darkBlue)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.darkBlue.opacity(0.7), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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
