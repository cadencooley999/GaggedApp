//
//  ProfileView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore
import PhotosUI

struct TopTab: Hashable {
    let title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}

struct ProfileView: View {
    
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("isAdmin") var isAdmin: Bool = false
    
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var windowSize: WindowSize
    @EnvironmentObject var homeViewModel: HomeViewModel
//    @EnvironmentObject var eventViewModel: EventViewModel
    @Environment(\.colorScheme) var scheme
    
    @Binding var selectedTab: TabBarItem
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var showEventView: Bool
    @Binding var showSettingsView: Bool
    @Binding var showProfileView: Bool
    @Binding var showPollView: Bool
    @Binding var showReportView: Bool
    @Binding var preReportInfo: preReportModel?
    @Binding var showInspectionView: Bool
    @Binding var postScreenType: ScreenType
    
    @State var showSearchSheet: Bool = false
    @State private var previousTabIndex: Int = 0
    @State var showImageOverlay: Bool = false
    @Namespace private var profilePicNamespace
    @State var isPressed: Bool = false
    
    private var isPadLike: Bool { windowSize.size.width >= 700 }
    private var headerTopPadding: CGFloat { isPadLike ? 24 : 0 }
    private var sectionTopPadding: CGFloat { isPadLike ? 24 : 8 }
    private var contentTopInset: CGFloat { isPadLike ? 228 : 132 }
    private var placeholderMinHeight: CGFloat { max(0, windowSize.size.height - contentTopInset - 60) }
    private var placeholderYOffset: CGFloat { isPadLike ? -200 : -120 }
    
    let topTabs: [TopTab] = [TopTab(title: "Posts"), TopTab(title: "Comments"), TopTab(title: "Polls"), TopTab(title: "Upvoted"), TopTab(title: "Saved")]
    
    @State var currentIndex: Int = 0
    
    @State var selectedTopTab: TopTab = TopTab(title: "Posts")
    
    private var commentColumns: [GridItem] {
        windowSize.size.width > 700
        ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        : [GridItem(.flexible(), spacing: 12)]
    }
    
    var body: some View {
        ZStack {
            Background()
                .frame(width: windowSize.size.width, height: windowSize.size.height)
            VStack {
                sectionTabCarousel
                    .padding(.horizontal, 8)
                    .padding(.top, 104)
            }
            VStack(spacing: 0){
                VStack(spacing: 0){
                    VStack(spacing: 0) {
                        header
                            .frame(height: isPadLike ? 64 : 55)
                            .padding(.horizontal)
                        profileInfo
                            .frame(maxWidth: .infinity)
                            .padding()
                            .padding(.bottom, isPadLike ? 12 : 0)
                    }
                    .padding(.top, headerTopPadding)
                    .background(Color.theme.background)
                    sectionPicker
                        .padding(.top, sectionTopPadding)
                        .frame(maxWidth: .infinity)
                        .background(alignment: .top) {
                            Rectangle()
                                .fill(Color.theme.background)
                                .mask(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .black.opacity(1.0), location: 0.0),
                                            .init(color: .black.opacity(0.97), location: 0.4),
                                            .init(color: .black.opacity(0.9), location: 0.5),
                                            .init(color: .black.opacity(0.85), location: 0.55),
                                            .init(color: .black.opacity(0.0), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: isPadLike ? 88 : 52)
                        }
                }
                Spacer()
            }
            if showImageOverlay {
                ImageOverlay(imageAddress: chosenProfileImageAddress, showImageOverlay: $showImageOverlay, namespace: profilePicNamespace)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showImageOverlay)
        .task {
            if windowSize.size.width > 700 {
                vm.postColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            }
            try? await vm.loadUserInfoIfNeeded()
            if !vm.hasLoadedPosts {
                await vm.loadInitialUserPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            }
        }
        .sheet(isPresented: $showSearchSheet) {

        }
        .gesture(
            DragGesture()
                .onEnded({ value in
                    if value.translation.width > 30 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showProfileView = false
                        }
                    }
                })
        )
    }
    
    var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showProfileView = false
                    }
                }
            Image(systemName: "eye")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .opacity(0)
            Spacer()
            Text("Profile")
                .font(.headline)
            Spacer()
            Image(systemName: "eye")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .opacity(isAdmin ? 1 : 0)
                .onTapGesture {
                    if isAdmin {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showInspectionView = true
                        }
                    }
                }
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettingsView = true
                    }
                }
        }
    }
    
    var profileInfo: some View {
        HStack(spacing: isPadLike ? 20 : 12){
            ZStack {
                ProfilePic(address: chosenProfileImageAddress, size: isPadLike ? 110 : 88)
            }
            .frame(width: isPadLike ? 110 : 88, height: isPadLike ? 110 : 88)
            .scaleEffect(isPressed ? 0.9 : 1)
            .onLongPressGesture(
                minimumDuration: 0.4,
                perform: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showImageOverlay = true
                        }
                        isPressed = false
                    })
                }
            )
            VStack(spacing: isPadLike ? 16 : 12){
                HStack {
                    Text("@\(vm.username)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .truncationMode(.tail)
                    if isAdmin {
                        Text("Admin")
                            .font(.subheadline.italic())
                            .foregroundStyle(Color.theme.darkBlue)
                            .padding(.leading, 4)
                    }
                    Spacer()
                }
                HStack(spacing: isPadLike ? 24 : 16){
                    HStack {
                        Text("\(vm.loadedUser.numPosts)")
                            .font(.body)
                            .fontWeight(.bold)
                        Text("Posts")
                            .font(.body)
                    }
                    Rectangle()
                        .frame(width: 0.5, height: 20)
                        .foregroundStyle(Color.theme.lightGray)
                    HStack {
                        Text("\(vm.loadedUser.gags)")
                            .font(.body)
                            .fontWeight(.bold)
                        Text("Gags")
                            .font(.body)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.leading, 4)
            }
            Spacer()
        }
    }
    
    var postSection: some View {
        ScrollView(showsIndicators: false)  {
            if vm.hasLoadedPosts {
                if !vm.userPosts.isEmpty {
                    LazyVGrid (columns: vm.postColumns, spacing: 8){
                        ForEach(vm.userPosts) { post in
                            TinyPostView(
                                post: post,
                                width: (windowSize.size.width - CGFloat((vm.postColumns.count + 1) * 8)) / CGFloat(max(1, vm.postColumns.count)),
                                height: ((windowSize.size.width - CGFloat((vm.postColumns.count + 1) * 8)) / CGFloat(max(1, vm.postColumns.count))) * (5/4)
                            )
                                .onTapGesture {
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
                                .onAppear {
                                    if post.id == vm.userPosts.last?.id {
                                        Task {
                                            await vm.getUserPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                        }
                                    }
                                }
                        }
                    }
                    .transition(.opacity)
                    .padding(.top, contentTopInset)
                    .padding(.bottom, vm.hasMoreUserPosts ? 300 : 0)
                } else {
                    VStack {
                        Spacer(minLength: 0)
                        Image(systemName: "camera")
                            .frame(width: 100, height: 100)
                        Text("No posts yet...")
                            .font(.title3)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: placeholderMinHeight)
                    .offset(y: placeholderYOffset)
                    .padding(.top, contentTopInset - 16)
                }
            } else {
                VStack {
                    Spacer(minLength: 0)
                    ProgressView()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: placeholderMinHeight)
                .offset(y: placeholderYOffset)
            }
        }
        .refreshable {
            await vm.loadInitialUserPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
        }
    }
    
    var commentSection: some View {
        ScrollView(showsIndicators: false)  {
            if vm.hasLoadedComments {
                if !vm.userComments.isEmpty  {
                    LazyVGrid(columns: commentColumns, spacing: 12) {
                        ForEach(vm.userComments) { comment in
                            HStack(alignment: .top, spacing: isPadLike ? 20 : 14) {
                                VStack {
                                    HStack(alignment: .top, spacing: 6) {
                                        ProfilePic(address: chosenProfileImageAddress, size: 30)
                                            .padding(.leading, 6)
                                            .padding(.top, 12)

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(username)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color.primary)

                                            Text(vm.formatFirestoreDate(comment.createdAt))
                                                .font(.footnote)
                                                .foregroundStyle(Color.secondary)
                                                .fontWeight(.regular)
                                            HStack {
                                                Text(comment.message)
                                                    .padding(12)
                                                    .background(Color.theme.lightGray.opacity(0.15))
                                                    .cornerRadius(8)
                                                HStack(spacing: 2){
                                                    Text("\(comment.upvotes)")
                                                    Image(systemName: "arrow.up")
                                                        .foregroundStyle(Color.theme.darkBlue)
                                                }
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            }
                                            .padding(.top, 8)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                }
                                .frame(
                                    maxWidth: ((windowSize.size.width - 32 - (isPadLike ? 12 : 0)) / CGFloat(isPadLike ? 2 : 1)) * (isPadLike ? 0.86 : 0.90),
                                    alignment: .leading
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .shadow(color: .black.opacity(0.10), radius: 8, x: 6)

                                Button {
                                    Task {
                                        let post = try await postViewModel.fetchPost(postId: comment.postId)
                                        selectedPost = post
                                        postViewModel.setPost(postSelection: post)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showPostView = true
                                        }
                                        postViewModel.commentsIsLoading = true
                                        try await postViewModel.loadInitialRootComments(blockedIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                        postViewModel.commentsIsLoading = false
                                    }
                                } label: {
                                    Image(systemName: "arrow.right")
                                        .font(.title3)
                                        .foregroundStyle(Color.theme.darkBlue)
                                        .padding(8)
                                        .frame(width: 36, height: 36)
                                        .contentShape(Rectangle())
                                        .glassEffect(.regular.interactive())
                                }
                            }
                            .onAppear {
                                if comment.id == vm.userComments.last?.id {
                                    Task {
                                        await vm.getUserComments(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, contentTopInset)
                    .padding(.horizontal)
                    .padding(.bottom, vm.hasMoreUserComments ? 300 : 0)
                } else {
                    VStack {
                        Spacer(minLength: 0)
                        Image(systemName: "ellipsis.message")
                            .frame(width: 100, height: 100)
                        Text("No comments yet...")
                            .font(.title3)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: placeholderMinHeight)
                    .offset(y: placeholderYOffset)
                    .padding(.top, contentTopInset - 16)
                }
            } else {
                VStack {
                    Spacer(minLength: 0)
                    ProgressView()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: placeholderMinHeight)
                .offset(y: placeholderYOffset)
            }
        }
        .task {
            if !vm.hasLoadedComments {
                await vm.loadInitialUserComments(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            }
        }
        .refreshable {
            await vm.loadInitialUserComments(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
        }
    }
    
    var pollSection: some View {
        ScrollView(showsIndicators: false)  {
            if vm.hasLoadedPolls {
                if !vm.userPolls.isEmpty {
                    LazyVStack (spacing: 8){
                        ForEach(vm.userPolls, id: \.compositeID) { poll in
                            MiniPollView(poll: poll, selectedPost: $selectedPost, showPostView: $showPostView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo, screenType: .profileFeed)
                                .padding()
                                .onTapGesture {
                                    if poll.options.count > 0 {
                                        vm.clearOptions(for: poll.id)
                                    } else {
                                        Task {
                                            try await vm.loadOptions(for: poll.id)
                                        }
                                    }
                                }
                                .onAppear {
                                    if poll.id == vm.userPolls.last?.id {
                                        Task {
                                            await vm.getUserPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.top, contentTopInset)
                    .padding(.bottom, vm.hasMoreUserPolls ? 300 : 0)
                } else if vm.userPolls.isEmpty {
                    VStack {
                        Spacer(minLength: 0)
                        Image(systemName: "chart.bar.horizontal.page")
                            .frame(width: 100, height: 100)
                        Text("No Polls Yet")
                            .font(.title3)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: placeholderMinHeight)
                    .offset(y: placeholderYOffset)
                    .padding(.top, contentTopInset)
                }
            } else {
                VStack {
                    Spacer(minLength: 0)
                    ProgressView()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: placeholderMinHeight)
                .offset(y: placeholderYOffset)
            }
        }
        .task {
            if !vm.hasLoadedPolls {
                await vm.loadInitialUserPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            }
        }
        .refreshable {
            PollCache.shared.clearCache()
            await vm.loadInitialUserPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
        }
    }
    
    var savedSection: some View {
        ScrollView(showsIndicators: false)  {
            if !vm.hasLoadedSaved {
                VStack {
                    Spacer(minLength: 0)
                    ProgressView()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: placeholderMinHeight)
                .offset(y: placeholderYOffset)
            } else {
                VStack(alignment: .leading, spacing: 0){
                    if vm.savedPosts.isEmpty && vm.savedPolls.isEmpty {
                        VStack {
                            Spacer(minLength: 0)
                            Image(systemName: "bookmark")
                                .frame(width: 100, height: 100)
                            Text("No saved posts or polls yet...")
                                .font(.title3)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: placeholderMinHeight)
                        .offset(y: placeholderYOffset - 10)
                    }
                    if !vm.savedPosts.isEmpty {
                        Text("Posts")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(8)
                            .padding(.bottom, 8)
                    }
                    LazyVGrid (columns: vm.postColumns, spacing: 8){
                        ForEach(vm.savedPosts) { post in
                            TinyPostView(
                                post: post,
                                width: (windowSize.size.width - CGFloat((vm.postColumns.count + 1) * 8)) / CGFloat(max(1, vm.postColumns.count)),
                                height: ((windowSize.size.width - CGFloat((vm.postColumns.count + 1) * 8)) / CGFloat(max(1, vm.postColumns.count))) * (5/4)
                            )
                                .onTapGesture {
                                    selectedPost = post
                                    postViewModel.setPost(postSelection: post)
                                    postScreenType = .savedFeed
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    Task {
                                        postViewModel.commentsIsLoading = true
                                        try await postViewModel.loadInitialRootComments(blockedIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                        postViewModel.commentsIsLoading = false
                                    }
                                }
                        }
                    }
                    if !vm.savedPolls.isEmpty {
                        Text("Polls")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                            .padding(8)
                    }
                    VStack (spacing: 8){
                        ForEach(vm.savedPolls, id: \.compositeID) { poll in
                            MiniPollView(poll: poll, selectedPost: $selectedPost, showPostView: $showPostView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo, screenType: .profileFeed)
                                .padding(8)
                                .onTapGesture {
                                    if poll.options.count > 0 {
                                        vm.savedClearOptions(for: poll.id)
                                    } else {
                                        Task {
                                            try await vm.savedLoadOptions(for: poll.id)
                                        }
                                    }
                                }
                        }
                    }
                }
                .padding(.top, contentTopInset)
            }
        }
        .refreshable {
            Task {
                PollCache.shared.clearCache()
                try await vm.refreshSaved(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            }
        }
        .task {
            Task {
                try await vm.loadSavedIfNeeded(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            }
        }
    }
    
    var upvotedSection: some View {
        ScrollView(showsIndicators: false)  {
            if vm.hasLoadedUpvoted {
                if !vm.upvotedPosts.isEmpty {
                    LazyVGrid (columns: vm.postColumns, spacing: 8){
                        ForEach(vm.upvotedPosts) { post in
                            TinyPostView(
                                post: post,
                                width: (windowSize.size.width - CGFloat((vm.postColumns.count + 1) * 8)) / CGFloat(max(1, vm.postColumns.count)),
                                height: ((windowSize.size.width - CGFloat((vm.postColumns.count + 1) * 8)) / CGFloat(max(1, vm.postColumns.count))) * (5/4)
                            )
                                .onTapGesture {
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
                                .onAppear {
                                    if post.id == vm.upvotedPosts.last?.id {
                                        Task {
                                            await vm.getUpvotedPosts()
                                        }
                                    }
                                }
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, contentTopInset)
                    .padding(.bottom, vm.hasMoreUpvotedPosts ? 300 : 0)
                } else if vm.upvotedPosts.isEmpty {
                    VStack {
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up")
                            .frame(width: 100, height: 100)
                        Text("Haven't seen anything you like?")
                            .font(.title3)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: placeholderMinHeight)
                    .offset(y: placeholderYOffset)
                    .padding(.top, contentTopInset - 10)
                }
            } else {
                VStack {
                    Spacer(minLength: 0)
                    ProgressView()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: placeholderMinHeight)
                .offset(y: placeholderYOffset)
            }
        }
        .refreshable {
            await vm.loadInitialUpvotedPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
        }
        .task {
            if !vm.hasLoadedUpvoted {
                await vm.loadInitialUpvotedPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
            }
        }
    }
    
    var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isPadLike ? 28 : 20) {
                ForEach(topTabs, id: \.self) { tab in
                    Text(tab.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(
                            selectedTopTab.title == tab.title ? Color.theme.background : Color.theme.accent
                        )
                        .padding(.vertical, isPadLike ? 12 : 8)
                        .padding(.horizontal, 12)
                        .onTapGesture {
                            print("TAPPED")
                            previousTabIndex = currentIndex
                            currentIndex = topTabs.firstIndex(of: tab)!
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTopTab = tab
                            }
                        }
                        .glassEffect(.regular.tint(selectedTopTab.title == tab.title ? Color.theme.darkBlue : .clear).interactive())
                }
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }

    
    var sectionTabCarousel: some View {
        ZStack {
            Group {
                switch selectedTopTab.title {
                case "Posts":
                    postSection
                case "Comments":
                    commentSection
                case "Polls":
                    pollSection
                case "Upvoted":
                    upvotedSection
                case "Saved":
                    savedSection
                default:
                    Background()
                }
            }
            // Dynamic transition based on navigation direction
            .transition(
                .asymmetric(
                    insertion: .move(edge: currentIndex > previousTabIndex ? .trailing : .leading),
                    removal: .move(edge: currentIndex > previousTabIndex ? .leading : .trailing)
                )
            )
            .animation(.easeInOut(duration: 0.25), value: selectedTopTab)
        }
    }
    

}
//
//struct searchSavedView: View {
//    
//    @EnvironmentObject var profileViewModel: ProfileViewModel
//    @EnvironmentObject var postViewModel: PostViewModel
//    
//    @Binding var selectedPost: PostModel?
//    @Binding var showPostView: Bool
//    @Binding var showEventView: Bool
//    
//    @Binding var showSearchSheet: Bool
//    
//    @FocusState var isFocused: Bool
//    
//    var body: some View {
//        ZStack {
//            Color.theme.background
//                .ignoresSafeArea()
//            ScrollView {
//                header
//                resultsSection
//            }
//        }
//        .task {
//            isFocused = true
//            profileViewModel.getSearchedPosts()
//        }
//    }
//    
//    var header: some View {
//        VStack(spacing: 0){
//            HStack {
//                Image(systemName: "chevron.left")
//                    .font(.headline)
//                    .padding(8)
//                    .onTapGesture {
//                        print("CHEV TAPPED")
//                        isFocused = false
//                        showSearchSheet = false
//                    }
//                TextField("Search saved...", text: $profileViewModel.searchText)
//                    .focused($isFocused)
//                    .padding(8)
//                    .background(Color.theme.lightGray.cornerRadius(5))
//                
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//            Divider()
//        }
//        .background(Color.theme.background)
//    }
//    
//    var resultsSection: some View {
//        VStack(spacing: 0) {
//            if profileViewModel.searchResults.isEmpty {
//                Text("No results found")
//                    .foregroundColor(.gray)
//                    .font(.caption)
//            }
//            else {
//                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
//                    // Create groups of 3 items: 2 small posts + 1 big event
//                    let grouped = stride(from: 0, to: profileViewModel.searchResults.count, by: 3).map {
//                        Array(profileViewModel.searchResults[$0..<min($0 + 3, profileViewModel.searchResults.count)])
//                    }
//
//                    ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
//                        // First row — two small posts if available
//                        GridRow {
//                            if group.count > 0 {
//                                mixedCell(group[0])
//                            }
//                            if group.count > 1 {
//                                mixedCell(group[1])
//                            }
//                        }
//
//                        // Second row — the event (or big item) if available
//                        if group.count > 2 {
//                            GridRow {
//                                mixedCell(group[2])
//                                    .gridCellColumns(2)
//                            }
//                        }
//                    }
//                }            }
//        }
//        .padding()
//    }
//    
//    @ViewBuilder
//    func mixedCell(_ mixed: MixedType) -> some View {
//        switch mixed {
//        case .post(let post):
//            TinyPostView(post: post, width: UIScreen.main.bounds.width / 2, height: 180)
//                .onTapGesture {
//                    selectedPost = post
//                    postViewModel.setPost(postSelection: post)
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        showSearchSheet = false
//                        showPostView = true
//                    }
//                    Task {
//                        postViewModel.commentsIsLoading = true
//                        try await postViewModel.fetchComments()
//                        postViewModel.commentsIsLoading = false
//                    }
//                }
//        case .event(let event):
//        }
//    }
//
//}

func loadSequentialImages(prefix: String) -> [String] {
    var results: [String] = []
    var i = 1

    while true {
        let name = "\(prefix)\(i)"

        // UIImage(named:) returns nil if the image doesn't exist
        if UIImage(named: name) == nil {
            break
        }

        results.append(name)
        i += 1
    }

    return results
}

struct ImageOverlay: View {
    
    @EnvironmentObject var profVM: ProfileViewModel
    
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress: String = ""
    @AppStorage("isAdmin") var isAdmin: Bool = false

    var imageAddress: String
    @State var addresses: [String] = loadSequentialImages(prefix: "ProfPic")
    
    @State private var newChosenAddress: String? = nil
    @Binding var showImageOverlay: Bool
    
    private var isPadLike: Bool { UIScreen.main.bounds.width >= 700 }
    private var gridItemSize: CGFloat { isPadLike ? 110 : 75 }
    private var gridSpacing: CGFloat { isPadLike ? 30 : 22 }
    
    var namespace: Namespace.ID
    
    @State private var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 72, maximum: 100), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: - Header
                HStack {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showImageOverlay = false
                            }
                        }
    
                    Spacer()
                    
                    Text("Change Profile Image")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .opacity(0)
                }
                .padding(.top, 12)
                
                Spacer()
                
                VStack {
                    // MARK: - Selected Image Preview
                    ProfilePic(address: newChosenAddress ?? imageAddress, size: isPadLike ? 220 : 200)
                        .padding(.bottom, 24)
                    
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(addresses, id: \.self) { address in
                            ProfilePic(address: address, size: gridItemSize)
                                .opacity(newChosenAddress == address ? 0.6 : 1)
                                .overlay(
                                    Circle()
                                        .stroke(newChosenAddress == address ? Color.theme.darkBlue : .clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    newChosenAddress = address
                                }
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                }
                
                Spacer()
                
                // MARK: - Save Button
                Button {
                    if newChosenAddress != nil {
                        Task {
                            chosenProfileImageAddress = newChosenAddress!
                            try await profVM.setNewProfileImage(address: newChosenAddress!)
                            showImageOverlay = false
                        }
                    }
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newChosenAddress != nil ? Color.theme.darkBlue : Color.theme.darkBlue.opacity(0.4))
                        .foregroundColor(Color.theme.background)
                        .cornerRadius(30)
                        .padding(.horizontal)
                }
                .disabled(newChosenAddress == nil)
                
            }
            .padding(.horizontal)
        }
        .onAppear {
            if isAdmin {
                addresses.append("AdminProfPic")
            }
            columns = [GridItem(.adaptive(minimum: gridItemSize, maximum: gridItemSize), spacing: gridSpacing)]
        }
    }
}

