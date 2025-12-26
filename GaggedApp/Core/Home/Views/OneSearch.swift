//
//  OneSearch.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/1/25.
//

import SwiftUI
import Foundation

enum SearchFilter: String, CaseIterable {
    case posts = "Posts"
    case polls = "Polls"
}

struct OneSearch: View {
    
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var locationManager: LocationManager
//    @EnvironmentObject var eventViewModel: EventViewModel
    
    @Binding var hideTabBar: Bool
    @Binding var selectedTab: TabBarItem
    @Binding var showPostView: Bool
    @Binding var showEventView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var searchViewFocused: Bool
    @FocusState var isFocused: Bool
    
    @Namespace private var segmentedSwitch
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            if searchViewModel.isLoading {
                CircularLoadingView(color: Color.theme.darkBlue)
                    .frame(width: 30, height: 30)
            }
            ScrollView {
                VStack {
                    contentFeed(currentFilter: searchViewModel.selectedFilter)
                        .opacity(searchViewModel.isLoading ? 0 : 1)
                }
                .padding(.top, 115)
            }
            .onScrollPhaseChange({ oldPhase, newPhase in
                if newPhase == .interacting {
                    UIApplication.shared.endEditing()
                }
            })
            VStack(spacing: 0){
                header
                    .frame(height: 55)
                    .background(.regularMaterial)
                segmentedController
                    .padding(.top, 8)
                    .frame(height: 55)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 { // left swipe
                        UIApplication.shared.endEditing()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard")
                        }
                        searchViewModel.searchText = ""
                    }
                }
        )
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                searchViewModel.addSubscribers {
                    locationManager.citiesInRange
                }
                isFocused = true
            })
        }
        .onChange(of: isFocused, perform: { isFocused in
            dismissKeyboard(isFocused: isFocused)
        })
    }
    
    func dismissKeyboard(isFocused: Bool) {
        if isFocused {
            hideTabBar = true
        }
        else {
            hideTabBar = false
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.theme.darkBlue)
                    .onTapGesture {
                        print("CHEV TAPPED")
                        UIApplication.shared.endEditing()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard")
                        }
                        searchViewModel.searchText = ""
                    }
                    .padding(.horizontal)
                Spacer()
                TextField("Search posts, polls, people...", text: $searchViewModel.searchText)
                    .focused($isFocused)
                    .onChange(of: isFocused) { shouldFocus in
                        searchViewFocused = shouldFocus
                    }
                    .onChange(of: searchViewFocused) { searchViewFocused in
                        isFocused = searchViewFocused
                    }
            }
            .padding()
            Divider()
        }

    }
    
    var segmentedController: some View {
        let selected = searchViewModel.selectedFilter

        return HStack(spacing: 6) {
            ForEach(SearchFilter.allCases, id: \.self) { filter in
                segmentButton(
                    title: filter.rawValue,
                    isSelected: selected == filter,
                    namespace: segmentedSwitch
                ) {
                    guard selected != filter else { return }

                    withAnimation(.easeInOut(duration: 0.25)) {
                        searchViewModel.isLoading = true
                        searchViewModel.selectedFilter = filter
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Material.thick)
//                .fill(Color.theme.lightGray.opacity(0.15))
        )
        .padding(.horizontal)
    }


    @ViewBuilder
    func segmentButton(
        title: String,
        isSelected: Bool,
        namespace: Namespace.ID,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            if isSelected {
                Capsule()
                    .fill(Color.theme.lightBlue.opacity(0.2))
                    .matchedGeometryEffect(id: "SEGMENT_PILL", in: namespace)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
            }

            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(Color.theme.darkBlue)
                .padding(.vertical, 6)
                .padding(.horizontal)
        }
        .contentShape(Capsule())
        .onTapGesture(perform: action)
        .frame(width: 100)
    }


    
//    var segmentedController: some View {
//        HStack(spacing: 0) {
//            Text("Posts")
//                .padding()
//                .background(searchViewModel.selectedFilter == "Posts" ? Color.theme.darkBlue : Color.clear)
//                .onTapGesture {
//                    if !(searchViewModel.selectedFilter == "Posts") {
//                        searchViewModel.postMatrix.removeAll()
//                        searchViewModel.isLoading = true
//                        searchViewModel.selectedFilter = "Posts"
//                    }
//                }
//                .padding(.horizontal)
//            Text("Polls")
//                .padding()
//                .background(searchViewModel.selectedFilter == "Polls" ? Color.theme.darkBlue : Color.clear)
//                .onTapGesture {
//                    if !(searchViewModel.selectedFilter == "Polls") {
//                        searchViewModel.pollList.removeAll()
//                        searchViewModel.isLoading = true
//                        searchViewModel.selectedFilter = "Polls"
//                    }
//                }
//                .padding(.horizontal)
//        }
//    }
    
    @ViewBuilder func contentFeed(currentFilter: SearchFilter) -> some View {
        ZStack {
            if currentFilter == .posts {
                postFeed
            }
            else {
                pollFeed
            }
        }
        .animation(.easeInOut(duration: 0.1), value: currentFilter)
    }
    
    var postFeed: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            HStack {
                ForEach(0..<searchViewModel.columns) { x in
                    VStack {
                        if searchViewModel.postMatrix.indices.contains(x) {
                            if !searchViewModel.postMatrix[x].isEmpty {
                                ForEach(searchViewModel.postMatrix[x], id: \.self) { post in
                                    MiniPostView(post: post, width: nil, stroked: nil)
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
    
    var pollFeed: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack {
                ForEach(searchViewModel.pollList, id: \.poll.id) { poll in
                    PollCard(poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView)
                        .padding(.bottom)
                }
            }
        }
    }
}

