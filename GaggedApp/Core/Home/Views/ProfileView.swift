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
    
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var windowSize: WindowSize
//    @EnvironmentObject var eventViewModel: EventViewModel
    @Environment(\.colorScheme) var scheme
    
    @Binding var selectedTab: TabBarItem
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var showEventView: Bool
    @Binding var showSettingsView: Bool
    @Binding var showProfileView: Bool
    
    @State var showSearchSheet: Bool = false
    @State private var previousTabIndex: Int = 0
    @State var showImageOverlay: Bool = false
    @Namespace private var animation
    @State var isPressed: Bool = false
    
    let topTabs: [TopTab] = [TopTab(title: "Posts"), TopTab(title: "Comments"), TopTab(title: "Polls"), TopTab(title: "Upvoted"), TopTab(title: "Saved"), TopTab(title: "Achievements")]
    
    @State var currentIndex: Int = 0
    
    @State var selectedTopTab: TopTab = TopTab(title: "Posts")
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
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
                            .frame(height: 55)
                            .padding(.horizontal)
                        profileInfo
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(.white)
                    sectionPicker
                        .frame(maxWidth: .infinity)
                        .background(Rectangle().fill(.white).mask(LinearGradient(stops: [
                            .init(color: .black.opacity(1), location: 0.1),
                            .init(color: .black.opacity(0.9), location: 0.5),
                            .init(color: .black.opacity(0.7), location: 0.7),
                                .init(color: .black.opacity(0), location: 1.0)
                        ], startPoint: .top, endPoint: .bottom)))
                }
                Spacer()
            }
            if showImageOverlay {
                ImageOverlay(imageAddress: chosenProfileImageAddress, showImageOverlay: $showImageOverlay)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showImageOverlay)
        .task {
            Task {
                try await vm.getUserPostsIfNeeded()
                try await vm.loadUserInfoIfNeeded()
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
            Spacer()
            Text("Profile")
                .font(.headline)
            Spacer()
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
        HStack(spacing: 12){
            ZStack {
                ProfilePic(address: chosenProfileImageAddress, size: 88)
            }
            .frame(width: 88, height: 88)
            .scaleEffect(isPressed ? 0.9 : 1)
            .onLongPressGesture(
                minimumDuration: 0.4,
                perform: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        showImageOverlay = true
                        isPressed = false
                    })
                }
            )
            VStack(spacing: 12){
                HStack {
                    Text("@\(vm.username)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .truncationMode(.tail)
                    Spacer()
                }
                HStack(spacing: 16){
                    HStack {
                        Text("\(vm.userPosts.count)")
                            .font(.body)
                            .fontWeight(.bold)
                        Text("Posts")
                            .font(.body)
                    }
                    Rectangle()
                        .frame(width: 0.5, height: 20)
                        .foregroundStyle(Color.theme.lightGray)
                    HStack {
                        Text("\(vm.loadedUser.garma)")
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
        ScrollView {
            if !vm.hasLoadedPosts {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: windowSize.size.width)
            } else if vm.userPosts.isEmpty {
                VStack {
                    Image(systemName: "camera")
                        .frame(width: 100, height: 100)
                    Text("No posts yet...")
                        .font(.title3)
                }
                .frame(maxWidth: windowSize.size.width)
                .padding(.top, 132)
            } else {
                LazyVGrid (columns: columns, spacing: 8){
                    ForEach(vm.userPosts) { post in
                        TinyPostView(post: post, width: windowSize.size.width / 3 - 16, height: (windowSize.size.width / 3 - 16)*(5/4))
                            .onTapGesture {
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
                }
                .padding(.top, 132)
            }
        }
        .refreshable {
            Task {
                try await vm.getMoreUserPosts()
            }
        }
    }
    
    var commentSection: some View {
        ScrollView {
            if !vm.hasLoadedComments {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if !vm.userComments.isEmpty {
                VStack(spacing: 12) {
                    ForEach(vm.userComments) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            // Card
                            HStack(alignment: .top, spacing: 12) {
                                ProfilePic(address: chosenProfileImageAddress, size: 30)
                                    .padding(.leading, 6)
                                    .padding(.top, 12)

                                VStack(alignment: .leading, spacing: 6) {
                                    // Username
                                    Text(username)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.primary)

                                    // Date
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
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.white)
                            )
                            .shadow(color: .black.opacity(0.10), radius: 8, x: 6)

                            Spacer()
                            
                            Button {
                                Task {
                                    let post = try await postViewModel.fetchPost(postId: comment.postId)
                                    selectedPost = post
                                    postViewModel.setPost(postSelection: post)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    postViewModel.commentsIsLoading = true
                                    try await postViewModel.fetchComments()
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
                    }
                }
                .padding(.top, 132)
                .padding(.horizontal)
            } else {
                VStack {
                    Image(systemName: "ellipsis.message")
                        .frame(width: 100, height: 100)
                    Text("No comments yet...")
                        .font(.title3)
                }
                .frame(maxWidth: windowSize.size.width)
                .padding(.top, 132)
            }
        }
        .task {
            Task {
                try await vm.getCommentsIfNeeded()
                print("Fetching Comments")
            }
        }
        .refreshable {
            Task {
                try await vm.getMoreUserComments()
            }
        }
    }
    
    var pollSection: some View {
        ScrollView {
            if !vm.hasLoadedPolls {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            if vm.userPolls.isEmpty {
                VStack {
                    Image(systemName: "chart.bar.horizontal.page")
                        .frame(width: 100, height: 100)
                    Text("No Polls Yet")
                        .font(.title3)
                }
                .frame(maxWidth: windowSize.size.width)
                .padding(.top, 132)
            }
            else {
                VStack (spacing: 8){
                    ForEach(vm.userPolls, id: \.poll.id) { poll in
                        MiniPollView(poll: poll, selectedPost: $selectedPost, showPostView: $showPostView)
                            .padding()
                            .onTapGesture {
                                if poll.options.count > 0 {
                                    vm.clearOptions(for: poll.poll.id)
                                } else {
                                    Task {
                                        try await vm.loadOptions(for: poll.poll.id)
                                    }
                                }
                            }
                    }
                }
                .padding(.top, 132)
            }
        }
        .task {
            Task {
                try await vm.getUserPollsIfNeeded()
            }
        }
        .refreshable {
            Task {
                print("refreshing")
                try await vm.getMoreUserPolls()
            }
        }
    }
    
    var savedSection: some View {
        ScrollView {
            if !vm.hasLoadedSaved {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0){
                    if vm.savedPosts.isEmpty && vm.savedPolls.isEmpty {
                        VStack {
                            Image(systemName: "bookmark")
                                .frame(width: 100, height: 100)
                            Text("No saved posts or events yet...")
                                .font(.title3)
                        }
                        .frame(maxWidth: windowSize.size.width)
                    }
                    if !vm.savedPosts.isEmpty {
                        Text("Posts")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(8)
                            .padding(.bottom, 8)
                    }
                    LazyVGrid (columns: columns, spacing: 8){
                        ForEach(vm.savedPosts) { post in
                            TinyPostView(post: post, width: windowSize.size.width / 3 - 16, height: (windowSize.size.width / 3 - 16)*(5/4))
                                .onTapGesture {
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
                    }
                    if !vm.savedPolls.isEmpty {
                        Text("Polls")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                            .padding(8)
                    }
                    VStack (spacing: 8){
                        ForEach(vm.savedPolls, id: \.poll.id) { poll in
                            MiniPollView(poll: poll, selectedPost: $selectedPost, showPostView: $showPostView)
                                .padding(8)
                                .onTapGesture {
                                    if poll.options.count > 0 {
                                        vm.savedClearOptions(for: poll.poll.id)
                                    } else {
                                        Task {
                                            try await vm.savedLoadOptions(for: poll.poll.id)
                                        }
                                    }
                                }
                        }
                    }
                }
                .padding(.top, 132)
            }
        }
        .refreshable {
            Task {
                try await vm.refreshSaved()
            }
        }
        .task {
            Task {
                try await vm.loadSavedIfNeeded()
            }
        }
    }
    
    var upvotedSection: some View {
        ScrollView {
            if !vm.hasLoadedUpvoted {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if vm.upvotedPosts.isEmpty {
                VStack {
                    Image(systemName: "arrow.up")
                        .frame(width: 100, height: 100)
                    Text("Haven't seen anything you like?")
                        .font(.title3)
                }
                .padding(.top, 132)
                .frame(width: windowSize.size.width)
            }
            else {
                LazyVGrid (columns: columns, spacing: 8){
                    ForEach(vm.upvotedPosts) { post in
                        TinyPostView(post: post, width: windowSize.size.width / 3 - 16, height: (windowSize.size.width / 3 - 16)*(5/4))
                            .onTapGesture {
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
                }
                .padding(.top, 132)
            }
        }
        .refreshable {
            print("refreshing")
            vm.getMoreUpvotedPosts()
        }
        .task {
            print("task")
            vm.getUpvotedPostsIfNeeded()
        }
    }
    
    var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(topTabs, id: \.self) { tab in
                    Text(tab.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(
                            selectedTopTab.title == tab.title ? .white : .primary
                        )
                        .padding(.vertical, 10)
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
            .padding(.vertical, 8)
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
                    Color.white
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

    var imageAddress: String
    let addresses = loadSequentialImages(prefix: "ProfPic")
    
    @State private var newChosenAddress: String? = nil
    @Binding var showImageOverlay: Bool
    
    @State private var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 72, maximum: 100), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
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
                            withAnimation(.easeInOut(duration: 0.2)) {
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
                    ProfilePic(address: newChosenAddress ?? imageAddress, size: 200)
                        .padding(.bottom, 24)
                    
                    HStack {
                        Spacer()
                        LazyVGrid(columns: columns) {
                            ForEach(addresses, id: \.self) { address in
                                ProfilePic(address: address, size: 75)
                                    .opacity(newChosenAddress == address ? 0.6 : 1)
                                    .overlay(
                                        Circle()
                                            .stroke(newChosenAddress == address ? Color.theme.darkBlue : .clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        newChosenAddress = address
                                    }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
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
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .padding(.horizontal)
                }
                .disabled(newChosenAddress == nil)
                
            }
            .padding(.horizontal)
        }
        .onAppear {
            // Using adaptive grid; no need to mutate columns per address
        }
    }
}

