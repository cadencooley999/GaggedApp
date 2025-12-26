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

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                    VStack {
                        Image(tab.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .frame(maxWidth: 120)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .foregroundColor(selectedTab == tab ? Color.theme.black : Color.theme.gray)
                    .onTapGesture {
                        if abs(index - (tabs.firstIndex(of: selectedTab) ?? 0)) > 1 {
                            selectedTab = tab
                        }
                        else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                        if selectedTab.title == "Search" {
                            searchViewFocused = true
                        }
                    }
                    .padding(.trailing, tab.title == "Polls" ? 36 : 0)
                    .padding(.leading, tab.title == "LeaderBoard" ? 36 : 0)
                }
                Spacer()
            }
            .background(.thinMaterial)
            .cornerRadius(30)
            VStack {
                AddPostIcon()
                    .frame(width: 12, height: 12)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAddPostView = true
                        }
                    }
            }

        }
        .padding(.horizontal, 40)
        .shadow(color: Color.theme.lightGray, radius: 5)
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

    let tabs: [TabBarItem]
    let content: Content

    init(tabs: [TabBarItem], selectedTab: Binding<TabBarItem>, hideTabBar: Binding<Bool>, showAddPostView: Binding<Bool>, showPostView: Binding<Bool>, showSearchView: Binding<Bool>, showEventView: Binding<Bool>, showEventSearchView: Binding<Bool>, selectedPost: Binding<PostModel?>, showSettingsView: Binding<Bool>, showProfileView: Binding<Bool>, searchViewFocused: Binding<Bool>, showCityPicker: Binding<Bool>, @ViewBuilder content: () -> Content) {
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
        self.tabs = tabs
        self.content = content()
    }

    var body: some View {
            ZStack {
                content
                VStack {
                    if selectedTab.title != "Search" {
                        VStack(spacing: 0){
                            HeaderView(showSearchView: $showSearchView, selectedTab: $selectedTab, showProfileView: $showProfileView, showCityPicker: $showCityPicker)
                                .frame(height: 55)
                            Divider()
                        }
                        .background(.regularMaterial)
                    }
                    Spacer()
                    CustomTabBarView(tabs: tabs, selectedTab: $selectedTab, showAddPostView: $showAddPostView, showPostView: $showPostView, hideTabBar: $hideTabBar, showSearchView: $showSearchView, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedPost: $selectedPost, showSettingsView: $showSettingsView, showProfileView: $showProfileView, searchViewFocused: $searchViewFocused, showCityPicker: $showCityPicker)
                        .opacity(hideTabBar ? 0 : 1)
                }

            }
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
    
    @Namespace private var postAnimation
    @State private var selectedPost: PostModel?

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            CustomTabBarContainerView(tabs: allTabs, selectedTab: $selectedTab, hideTabBar: $hideTabBar, showAddPostView: $showAddPostView, showPostView: $showPostView, showSearchView: $showSearchView, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedPost: $selectedPost, showSettingsView: $showSettingsView, showProfileView: $showProfileView, searchViewFocused: $searchViewFocused, showCityPicker: $showCityPicker) {
                ZStack {
                    TabView(selection: $selectedTab){
                        HomeView(hideTabBar: $hideTabBar, showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab, postAnimation: postAnimation)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .tag(allTabs[0])
                        PollsView(selectedTab: $selectedTab, hideTabBar: $hideTabBar, selectedPost: $selectedPost, showPostView: $showPostView)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .tag(allTabs[1])
                        LeaderView(showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .tag(allTabs[2])
                        OneSearch(hideTabBar: $hideTabBar, selectedTab: $selectedTab, showPostView: $showPostView, showEventView: $showEventView, selectedPost: $selectedPost, searchViewFocused: $searchViewFocused)
                            .frame(width: UIScreen.main.bounds.width)
                            .tag(allTabs[3])
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
                .sheet(isPresented: $showCityPicker) {
                    CityPickerView(dissmissable: false, showCityPickerView: $showCityPicker)
                }
            }
            if showProfileView {
                ProfileView(selectedTab: $selectedTab, selectedPost: $selectedPost, showPostView: $showPostView, showEventView: $showEventView, showSettingsView: $showSettingsView, showProfileView: $showProfileView)
                    .zIndex(1)
                    .transition(.move(edge: .trailing))
            }
            if showAddPostView {
                AddPostView(showAddPostView: $showAddPostView)
                    .zIndex(1)
                    .transition(.move(edge: .bottom))
            }
            if let post = selectedPost, showPostView {
                PostView(showPostView: $showPostView, showSearchView: $showSearchView, hideTabBar: $hideTabBar)
                    .zIndex(3)
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


