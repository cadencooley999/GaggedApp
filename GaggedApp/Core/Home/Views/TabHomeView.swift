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
    @Binding var showPostView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showSearchView: Bool
    @Binding var showEventView: Bool
    @Binding var showEventSearchView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var showSettingsView: Bool
    @Binding var showProfileView: Bool
    @Binding var searchViewFocused: Bool
    @Binding var showCityPicker: Bool
    @Binding var showSearchBar: Bool
    
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
                                            .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
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
                        CustomTabBarView(tabs: tabs, selectedTab: $selectedTab, showAddPostView: $showAddPostView, showPostView: $showPostView, hideTabBar: $hideTabBar, showSearchView: $showSearchView, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedPost: $selectedPost, showSettingsView: $showSettingsView, showProfileView: $showProfileView, searchViewFocused: $searchViewFocused, showCityPicker: $showCityPicker, showSearchBar: $showSearchBar, animatedSelection: selectedTab)
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
    
    @Namespace private var postAnimation
    @State private var selectedPost: PostModel?

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
                        .white.opacity(0.06),
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
                        HomeView(hideTabBar: $hideTabBar, showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab, postAnimation: postAnimation)
                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .tag(allTabs[0])
                        PollsView(selectedTab: $selectedTab, hideTabBar: $hideTabBar, selectedPost: $selectedPost, showPostView: $showPostView)
                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .tag(allTabs[1])
                        LeaderView(showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab)
                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .tag(allTabs[2])
                        OneSearch(hideTabBar: $hideTabBar, selectedTab: $selectedTab, showPostView: $showPostView, showEventView: $showEventView, selectedPost: $selectedPost, searchViewFocused: $searchViewFocused, showSearchBar: $showSearchBar)
//                            .frame(width: windowSize.size.width, height: windowSize.size.height)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .tag(allTabs[3])
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(nil, value: selectedTab)   // 🔥 THIS is the kill switch
                    .ignoresSafeArea()
                }
                .sheet(isPresented: $showCityPicker) {
                    CityPickerView(dissmissable: true, showCityPickerView: $showCityPicker)
                }
            }
            if showProfileView {
                ProfileView(selectedTab: $selectedTab, selectedPost: $selectedPost, showPostView: $showPostView, showEventView: $showEventView, showSettingsView: $showSettingsView, showProfileView: $showProfileView)
                    .zIndex(1)
                    .transition(.move(edge: .trailing))
            }
            if showAddPostView {
                AddPostView(showAddPostView: $showAddPostView)
                    .zIndex(3)
                    .transition(.move(edge: .bottom))
            }
            if let post = selectedPost, showPostView {
                PostView(showPostView: $showPostView, showSearchView: $showSearchView, hideTabBar: $hideTabBar, showAddPostView: $showAddPostView)
                    .zIndex(2)
                    .opacity(1)
            }
            if showSettingsView {
                SettingsView(showSettingsView: $showSettingsView)
                    .zIndex(4)
                    .transition(.move(edge: .trailing))
            }
        }
    }
    
    func onSwipeLeft() {

    }
    
    func onSwipeRight() {

    }
}

