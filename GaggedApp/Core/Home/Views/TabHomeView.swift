//
//  TabHomeView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/4/25.
//
import SwiftUI

// MARK: - Custom Tab Bar View
struct CustomTabBarView: View {
    let tabs: [TabBarItem]
    @Binding var selectedTab: TabBarItem
    @Binding var showAddPostView: Bool
    
    @EnvironmentObject var addPostViewModel: AddPostViewModel
    
    @State var animatedSelection: TabBarItem
    
    @Namespace private var selectionPill

    var body: some View {
        GlassEffectContainer(){
            HStack(spacing: 12){
                Image(systemName: "plus")
                    .font(.title2)
                    .padding()
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) {
                            showAddPostView = true
                            addPostViewModel.currentNewContent = selectedTab.title == "Polls" ? NewContent.poll : NewContent.post
                        }
                    }
                HStack {
                    ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                        ZStack {
                            if animatedSelection == tab {
                                Capsule(style: .continuous)
                                    .fill(Color.theme.lightBlue.opacity(0.2 ))
                                    .frame(width: 70, height: 45)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.theme.background.opacity(0.25), lineWidth: 0.5)
                                    )
                                    .matchedGeometryEffect(id: 1, in: selectionPill)
                                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
                            }

                            Image(tab.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                
                        }
                        .frame(width: 40, height: 50)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())              // 👈 tappable everywhere
                        .onTapGesture {
                            // 1️⃣ Disable animation for TabView navigation
                            withTransaction(Transaction(animation: nil)) {
                                selectedTab = tab
                            }

                            // 2️⃣ Animate the pill ONLY
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                animatedSelection = tab
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .onChange(of: selectedTab) { newValue in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        animatedSelection = newValue
                    }
                }
                .glassEffect()
            }
        }
    }
}

// MARK: - Container View
struct CustomTabBarContainerView<Content: View>: View {

    @Binding var selectedTab: TabBarItem
    @Binding var hideTabBar: Bool
    @Binding var showAddPostView: Bool
    @Binding var showPostView: Bool
    @Binding var showSearchView: Bool
    @Binding var showEventView: Bool
    @Binding var showEventSearchView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var showSettingsView: Bool
    @Binding var showProfileView: Bool
    @Binding var searchViewFocused: Bool
    @Binding var showCityPicker: Bool
    @Binding var showSearchBar: Bool
    
    var isSearchTab: Bool {
        selectedTab.title == "Search"
    }

    let tabs: [TabBarItem]
    let content: Content

    init(tabs: [TabBarItem], selectedTab: Binding<TabBarItem>, hideTabBar: Binding<Bool>, showAddPostView: Binding<Bool>, showPostView: Binding<Bool>, showSearchView: Binding<Bool>, showEventView: Binding<Bool>, showEventSearchView: Binding<Bool>, selectedPost: Binding<PostModel?>, showSettingsView: Binding<Bool>, showProfileView: Binding<Bool>, searchViewFocused: Binding<Bool>, showCityPicker: Binding<Bool>, showSearchBar: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self._hideTabBar = hideTabBar
        self._showAddPostView = showAddPostView
        self._showPostView = showPostView
        self._showSearchView = showSearchView
        self._showEventView = showEventView
        self._showEventSearchView = showEventSearchView
        self._selectedPost = selectedPost
        self._showSettingsView = showSettingsView
        self._showProfileView = showProfileView
        self._searchViewFocused = searchViewFocused
        self._showCityPicker = showCityPicker
        self._showSearchBar = showSearchBar
        self.tabs = tabs
        self.content = content()
    }

    @Environment(\.colorScheme) var scheme

    var body: some View {
            ZStack {
                content
                VStack {
                    if !isSearchTab {
                        ZStack {
                            VStack {
                                BackgroundHelper.shared.appleHeaderBlur.frame(height: 92)
                                Spacer()
                            }
                            VStack {
                                HeaderView(showSearchView: $showSearchView, selectedTab: $selectedTab, showProfileView: $showProfileView, showCityPicker: $showCityPicker)
                                    .frame(height: 55)
                                Spacer()
                            }
                        }
                        .transition(.opacity
//                            .move(edge: .top)
//                            .combined(with: .opacity)
                        )
                    
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        CustomTabBarView(tabs: tabs, selectedTab: $selectedTab, showAddPostView: $showAddPostView, animatedSelection: TabBarItem(iconName: "HomeIcon", title: "Home"))
                            .opacity(hideTabBar ? 0 : 1)
                        Spacer()
                    }
                }

            }
            .ignoresSafeArea(.keyboard)
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
    }
}

// MARK: - Home View
struct TabHomeView: View {
    let allTabs = [
        TabBarItem(iconName: "HomeIcon", title: "Home"),
        TabBarItem(iconName: "PollIcon", title: "Polls"),
        TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard"),
        TabBarItem(iconName: "SearchIcon", title: "Search")
    ]
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var windowSize: WindowSize
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var pollsViewModel: PollsViewModel
    

    @State private var selectedTab: TabBarItem = TabBarItem(iconName: "HomeIcon", title: "Home")
    @State var hideTabBar: Bool = false
    @State var showAddPostView: Bool = false
    @State var showPostView: Bool = false
    @State var showSearchView: Bool = false
    @State var showEventView: Bool = false
    @State var showEventSearchView: Bool = false
    @State var showSettingsView: Bool = false
    @State var showProfileView: Bool = false
    @State var showCityPicker: Bool = false
    @State var searchViewFocused: Bool = false
    @State var showSearchBar: Bool = false
    @State var showPollView: Bool = false
    @State var showReportView: Bool = false
    @State var preReportInfo: preReportModel? = nil
    @State var showInspectionView: Bool = false
    @State var postScreenType: ScreenType = .homeFeed
    
    @Namespace private var postAnimation
    @State private var selectedPost: PostModel?
    @State private var selectedPoll: PollWithOptions?

    var body: some View {
        ZStack {
            ZStack {
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
                        Color.theme.background.opacity(0.06),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxWidth: windowSize.size.width, maxHeight: windowSize.size.height)
            CustomTabBarContainerView(tabs: allTabs, selectedTab: $selectedTab, hideTabBar: $hideTabBar, showAddPostView: $showAddPostView, showPostView: $showPostView, showSearchView: $showSearchView, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedPost: $selectedPost, showSettingsView: $showSettingsView, showProfileView: $showProfileView, searchViewFocused: $searchViewFocused, showCityPicker: $showCityPicker, showSearchBar: $showSearchBar) {
                ZStack {
                    TabView(selection: $selectedTab){
                        HomeView(hideTabBar: $hideTabBar, showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab, postScreenType: $postScreenType, postAnimation: postAnimation)
                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .tag(allTabs[0])
                        PollsView(selectedTab: $selectedTab, hideTabBar: $hideTabBar, selectedPost: $selectedPost, showPostView: $showPostView, selectedPoll: $selectedPoll, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo)
                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .tag(allTabs[1])
                        LeaderView(showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab, postScreenType: $postScreenType)
                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .tag(allTabs[2])
                        OneSearch(hideTabBar: $hideTabBar, selectedTab: $selectedTab, showPostView: $showPostView, showEventView: $showEventView, selectedPost: $selectedPost, searchViewFocused: $searchViewFocused, showSearchBar: $showSearchBar, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo, postScreenType: $postScreenType)
//                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .tag(allTabs[3])
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(nil, value: selectedTab)   // 🔥 THIS is the kill switch
                    .ignoresSafeArea()
                }
                .sheet(isPresented: $showCityPicker) {
                    CityPickerView(dissmissable: true, showCityPickerView: $showCityPicker, selectedTab: $selectedTab)
                }
                .fullScreenCover(isPresented: $showReportView) {
                    ReportSheetView(showReportSheet: $showReportView, preReportInfo: $preReportInfo)
                }
            }
            if showInspectionView {
                InspectionView(showInspectionView: $showInspectionView, selectedPost: $selectedPost, showPostView: $showPostView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo)
                    .zIndex(2)
            }
            if showProfileView {
                ProfileView(selectedTab: $selectedTab, selectedPost: $selectedPost, showPostView: $showPostView, showEventView: $showEventView, showSettingsView: $showSettingsView, showProfileView: $showProfileView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo, showInspectionView: $showInspectionView, postScreenType: $postScreenType)
                    .zIndex(1)
                    .transition(.move(edge: .trailing))
            }
            if showAddPostView {
                AddPostView(showAddPostView: $showAddPostView, selectedTab: $selectedTab)
                    .zIndex(4)
                    .transition(.move(edge: .bottom))
            }

            // iPad-style popup vs iPhone full-screen
            Group {
                if let post = selectedPost, showPostView {
                    if windowSize.size.width >= 700 { // Treat as iPad/regular width
                        // Backdrop
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPostView = false
                                }
                            }
                        // Centered popup container
                        VStack {
                            Spacer(minLength: 0)
                            ZStack {
                                PostView(
                                    showPostView: $showPostView,
                                    showSearchView: $showSearchView,
                                    hideTabBar: $hideTabBar,
                                    showAddPostView: $showAddPostView,
                                    showPollView: $showPollView,
                                    showProfileView: $showProfileView,
                                    showReportSheet: $showReportView,
                                    preReportInfo: $preReportInfo,
                                    screenType: $postScreenType
                                )
                            }
                            .frame(maxWidth: min(windowSize.size.width * 0.75, 800),
                                   maxHeight: min(windowSize.size.height * 0.95, 1000))
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
                            .padding(.horizontal)
                            Spacer(minLength: 0)
                        }
                        .zIndex(3)
                    } else {
                        // iPhone: keep full-screen
                        PostView(
                            showPostView: $showPostView,
                            showSearchView: $showSearchView,
                            hideTabBar: $hideTabBar,
                            showAddPostView: $showAddPostView,
                            showPollView: $showPollView,
                            showProfileView: $showProfileView,
                            showReportSheet: $showReportView,
                            preReportInfo: $preReportInfo,
                            screenType: $postScreenType
                        )
                        .zIndex(3)
                        .opacity(1)
                        .transition(.opacity)
                    }
                }
            }

            if let poll = selectedPoll, showPollView {
                PollView(showPollView: $showPollView, showPostView: $showPostView, selectedPoll: $selectedPoll, showReportView: $showReportView, preReportInfo: $preReportInfo, selectedPost: $selectedPost)
                    .zIndex(2)
            }
            if showSettingsView {
                SettingsView(selectedTab: $selectedTab, showSettingsView: $showSettingsView)
                    .zIndex(4)
                    .transition(.move(edge: .trailing))
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermissionIfNeeded()
        }
        .onOpenURL(perform: { url in
            handle(url)
        })
    }
    
    func handle(_ url: URL) {
        print("handling url: ", url)
        
        let components = url.pathComponents
        
        let type: String
        let id: String
        
        if url.scheme == "https" || url.scheme == "http" {
            // Web link
            guard components.count >= 3 else { return }
            type = components[1] // post / poll
            id = components[2]   // actual id
        } else {
            // Custom scheme link
            print(components)
            guard components.count >= 2 else { return }
            type = url.host() ?? ""// post / poll
            id = components[1]   // actual id
        }
        
        print("type:", type, "id:", id)
        
        switch type {
        case "post":
            Task {
                try await navigateToPost(id)
            }
        case "poll":
            Task {
                try await navigateToPoll(id)
            }
        default:
            break
        }
    }
    
    func navigateToPost(_ id: String) async throws {
        print("navigating to: ", id)
        selectedTab = TabBarItem(iconName: "HomeIcon", title: "Home")
        let post = try await postViewModel.fetchPost(postId: id)
        selectedPost = post
        postViewModel.setPost(postSelection: post)
        withAnimation(.easeInOut(duration: 0.2)) {
            showPostView = true
        }
        Task {
            postViewModel.commentsIsLoading = true
            try await postViewModel.loadInitialRootComments(blockedIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            postViewModel.commentsIsLoading = false
        }
    }
    
    func navigateToPoll(_ id: String) async throws {
        print("navigating to: ", id)
        selectedTab = TabBarItem(iconName: "PollIcon", title: "Polls")
        let poll = try await pollsViewModel.fetchPoll(id: id)
        selectedPoll = poll
        pollsViewModel.poll = poll
        withAnimation(.easeInOut(duration: 0.2)) {
            showPollView = true
        }
    }
    
    func onSwipeLeft() {

    }
    
    func onSwipeRight() {

    }
}

