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

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                ForEach(tabs, id: \.self) { tab in
                    VStack {
                        Image(tab.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .frame(maxWidth: 200)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .foregroundColor(selectedTab == tab ? Color.theme.black : Color.theme.gray)
                    .onTapGesture {
                        selectedTab = tab
                    }
                    .padding(.trailing, tab.title == "Home" ? 48 : 0)
                    .padding(.leading, tab.title == "Events" ? 48 : 0)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .background(Color.theme.background.shadow(color: Color.black.opacity(0.05), radius: 10, y: -13).cornerRadius(30))
            VStack {
                AddPostIcon()
                    .frame(width: 36, height: 36)
                    .padding(.bottom)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hideTabBar = true
                            showAddPostView = true
                        }
                    }
            }

        }
        .padding(16)
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

    let tabs: [TabBarItem]
    let content: Content

    init(tabs: [TabBarItem], selectedTab: Binding<TabBarItem>, hideTabBar: Binding<Bool>, showAddPostView: Binding<Bool>, showPostView: Binding<Bool>, showSearchView: Binding<Bool>, showEventView: Binding<Bool>, showEventSearchView: Binding<Bool>, selectedPost: Binding<PostModel?>, showSettingsView: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self._hideTabBar = hideTabBar
        self._showAddPostView = showAddPostView
        self._showPostView = showPostView
        self._showSearchView = showSearchView
        self._showEventView = showEventView
        self._showEventSearchView = showEventSearchView
        self._selectedPost = selectedPost
        self._showSettingsView = showSettingsView
        self.tabs = tabs
        self.content = content()
    }

    var body: some View {
            ZStack {
                content
                VStack {
                    Spacer()
                    CustomTabBarView(tabs: tabs, selectedTab: $selectedTab, showAddPostView: $showAddPostView, showPostView: $showPostView, hideTabBar: $hideTabBar, showSearchView: $showSearchView, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedPost: $selectedPost, showSettingsView: $showSettingsView)
                        .offset(y: hideTabBar ? 100 : 0)
                }
                .ignoresSafeArea()
            }
    }
}

// MARK: - Home View
struct TabHomeView: View {
    let allTabs = [
        TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard"),
        TabBarItem(iconName: "HomeIcon", title: "Home"),
        TabBarItem(iconName: "EventsIcon", title: "Events"),
        TabBarItem(iconName: "ProfileIcon", title: "Profile")
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
    
    @Namespace private var postAnimation
    @State private var selectedPost: PostModel?

    var body: some View {
        CustomTabBarContainerView(tabs: allTabs, selectedTab: $selectedTab, hideTabBar: $hideTabBar, showAddPostView: $showAddPostView, showPostView: $showPostView, showSearchView: $showSearchView, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedPost: $selectedPost, showSettingsView: $showSettingsView) {
            ZStack {
                switch selectedTab.title {
                case "Home":
                    HomeView(hideTabBar: $hideTabBar, showPostView: $showPostView, showSearchView: $showSearchView, selectedPost: $selectedPost, selectedTab: $selectedTab, postAnimation: postAnimation)
                        .zIndex(selectedTab.title == "Home" ? 1 : 0)
                        .opacity(selectedTab.title == "Home" ? 1 : 0)
                        .allowsHitTesting(selectedTab.title == "Home")
                case "Profile":
                    ProfileView(selectedTab: $selectedTab, selectedPost: $selectedPost, showPostView: $showPostView, hideTabBar: $hideTabBar, showEventView: $showEventView, showSettingsView: $showSettingsView)
                        .zIndex(selectedTab.title == "Profile" ? 1 : 0)
                        .opacity(selectedTab.title == "Profile" ? 1 : 0)
                        .allowsHitTesting(selectedTab.title == "Profile")
                case "LeaderBoard":
                    LeaderView(hideTabBar: $hideTabBar, showPostView: $showPostView, selectedPost: $selectedPost, selectedTab: $selectedTab)
                        .zIndex(selectedTab.title == "LeaderBoard" ? 1 : 0)
                        .opacity(selectedTab.title == "LeaderBoard" ? 1 : 0)
                        .allowsHitTesting(selectedTab.title == "LeaderBoard")
                case "Events":
                    EventsView(hideTabBar: $hideTabBar, showEventView: $showEventView, showEventSearchView: $showEventSearchView, selectedTab: $selectedTab)
                        .zIndex(selectedTab.title == "Events" ? 1 : 0)
                        .opacity(selectedTab.title == "Events" ? 1 : 0)
                        .allowsHitTesting(selectedTab.title == "Events")
                default:
                    Color.theme.background
                }
                if showAddPostView {
                    AddPostView(showAddPostView: $showAddPostView, hideTabBar: $hideTabBar)
                        .zIndex(2)
                        .opacity(1)
                        .allowsHitTesting(showAddPostView)
                        .transition(.move(edge: .bottom))
                }
                if let post = selectedPost, showPostView {
                    PostView(showPostView: $showPostView, hideTabBar: $hideTabBar, showSearchView: $showSearchView)
                        .zIndex(4)
                        .opacity(1)
                        .allowsHitTesting(showPostView)
                }
                if showSearchView {
                    SearchView(showSearchView: $showSearchView, hideTabBar: $hideTabBar, showPostView: $showPostView)
                        .zIndex(2)
                        .allowsHitTesting(showSearchView)
                        .transition(.move(edge: .trailing))
                }
                if showEventView {
                    EventView(showEventView: $showEventView, hideTabBar: $hideTabBar, showEventSearchView: $showEventSearchView)
                        .zIndex(4)
                }
                if showEventSearchView {
                    EventSearchView(showEventSearchView: $showEventSearchView, hideTabBar: $hideTabBar, showEventView: $showEventView)
                        .zIndex(2)
                        .transition(.move(edge: .trailing))
                }
                if showSettingsView {
                    SettingsView(showSettingsView: $showSettingsView, hideTabBar: $hideTabBar)
                        .zIndex(2)
                        .transition(.move(edge: .trailing))
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        if horizontalAmount < -70 {
                            // Swiped left
                            onSwipeLeft()
                        } else if horizontalAmount > 70 {
                            // Swiped right
                            onSwipeRight()
                        }
                    }
            )
        }
    }
    
    func onSwipeLeft() {

    }
    
    func onSwipeRight() {

    }
}

// MARK: - Preview
#Preview {
    TabHomeView()
        .environmentObject(HomeViewModel.previewModel())
}

