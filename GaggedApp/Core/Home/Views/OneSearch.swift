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
    @EnvironmentObject var windowSize: WindowSize
//    @EnvironmentObject var eventViewModel: EventViewModel
    
    @Binding var hideTabBar: Bool
    @Binding var selectedTab: TabBarItem
    @Binding var showPostView: Bool
    @Binding var showEventView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var searchViewFocused: Bool
    @Binding var showSearchBar: Bool
    @FocusState var isFocused: Bool
    
    @State var showxmark: Bool = false
    
    var isSearchTab: Bool {
        selectedTab.title == "Search"
    }
    
    @Namespace private var segmentedSwitch
    @Namespace var searchBar
    
    var body: some View {
        ZStack {
            Background()
                .frame(maxWidth: windowSize.size.width, maxHeight: windowSize.size.height)
            if searchViewModel.isLoading {
                CircularLoadingView(color: Color.theme.darkBlue)
                    .frame(width: 30, height: 30)
            }
            ScrollView {
                VStack {
                    contentFeed(currentFilter: searchViewModel.selectedFilter)
                }
                .padding(.top, 160)
                .padding(.bottom, 100)
            }
            .onScrollPhaseChange({ oldPhase, newPhase in
                if newPhase == .interacting {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFocused = false
                    }
                }
            })
            if isSearchTab {
                VStack {
                    header
                        .frame(height: 55)
                        .padding(.top, 55)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isFocused = true
                            }
                        }
                    Spacer()
                }
                .transition(.opacity)
            }
            VStack {
                segmentedController
                    .padding(.top, 215)
                    .frame(height: 55)
                Spacer()
            }
        }
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                searchViewModel.addSubscribers {
                    locationManager.citiesInRange
                }
            })
        }
        .animation(.easeInOut(duration: 0.3), value: isSearchTab)
    }
    
    var header: some View {
        VStack(spacing: 0) {
            GlassEffectContainer {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.theme.darkBlue)
                        TextField("Search by name, author, tags...", text: $searchViewModel.searchText)
                            .focused($isFocused)
                        if !searchViewModel.searchText.isEmpty {
                            Button {
                                searchViewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.theme.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = true
                    }
                    .glassEffect()
                    .glassEffectID("bar", in: searchBar)
                    .glassEffectTransition(.materialize)
                    
                    if showxmark {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 36, height: 36)
                            .padding(8)
                            .contentShape(Rectangle())
                            .glassEffect()
                            .glassEffectID("xmark", in: searchBar)
                            .glassEffectTransition(.matchedGeometry)
                            .onTapGesture {
                                isFocused = false
                            }
                    }
                }
                .onChange(of: isFocused) {
                    showxmark = isFocused
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .animation(.easeInOut(duration: 0.3), value: showxmark)
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
        .padding(2)
        .glassEffect()
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
                    .background(            ZStack {
                        Color(uiColor: .systemBackground)

                        Image("noise")
                            .resizable()
                            .scaledToFill()
                            .blendMode(.overlay)
                    }
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.06),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ))
            }
            else {
                pollFeed
                    .background(            ZStack {
                        Color(uiColor: .systemBackground)

                        Image("noise")
                            .resizable()
                            .scaledToFill()
                            .blendMode(.overlay)
                    }
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.06),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ))
            }
        }
    }
    
    var postFeed: some View {
        ZStack {
            HStack {
                ForEach(0..<searchViewModel.columns) { x in
                    VStack {
                        if searchViewModel.postMatrix.indices.contains(x) {
                            if !searchViewModel.postMatrix[x].isEmpty {
                                ForEach(searchViewModel.postMatrix[x], id: \.self) { post in
                                    MiniPostView(post: post, width: nil, stroked: nil)
                                        .id("\(post.id)-\(post.upvotes)-\(post.downvotes)")
                                        .contentShape(Rectangle())
                                        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
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
        .padding(.horizontal)
    }
    
    var pollFeed: some View {
        ZStack {
            VStack {
                ForEach(searchViewModel.pollList, id: \.poll.id) { poll in
                    PollCard(poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView)
                        .contentShape(Rectangle())
                        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                        .padding(.bottom)
                        
                }
            }
        }
        .padding(.horizontal)
    }
}

