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
//    @EnvironmentObject var eventViewModel: EventViewModel
    
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
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            VStack(spacing: 0){
                profileInfo
                    .frame(maxWidth: .infinity)
                    .padding()
                    .frame(maxHeight: UIScreen.main.bounds.height/4)
                sectionPicker
                    .frame(maxWidth: .infinity)
                Divider()
                sectionTabCarousel
                    .padding(.horizontal, 8)
            }
            if showImageOverlay {
                ImageOverlay(imageAddress: chosenProfileImageAddress, showImageOverlay: $showImageOverlay)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showImageOverlay)
        .task {
            Task {
                vm.sectionLoading = "posts"
                try await vm.getUserPostsIfNeeded()
                try await vm.loadUserInfo()
                vm.sectionLoading = ""
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
    
    var profileInfo: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(8)
                    .background(Color.theme.background)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showProfileView = false
                        }
                    }
                Text("@\(vm.username)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "gear")
                    .font(.title2)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettingsView = true
                        }
                    }
            }
            Spacer()
            HStack {
                ZStack {
                    ProfilePic(address: chosenProfileImageAddress, size: 120)
                }
                .frame(width: 120, height: 120)
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
                .padding()
                VStack(spacing: 6){
                    HStack {
                        Text("\(vm.userPosts.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("posts")
                            .font(.body)
                    }
                    HStack {
                        Text("\(vm.loadedUser.garma)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("garma")
                            .font(.body)
                    }
                }
                .padding(.leading, 32)
                Spacer()
            }
            Spacer()
        }
    }
    
    var postSection: some View {
        ScrollView {
            if vm.sectionLoading == "posts" {
                ProgressView()
                    .padding(.top, 40)
            }
            if vm.userPosts.isEmpty {
                ZStack {
                    Color.theme.background
                    VStack {
                        Image(systemName: "camera")
                            .frame(width: 100, height: 100)
                        Text("No posts yet...")
                            .font(.title3)
                    }
                    .padding(.top, 40)
                }
            }
            else {
                LazyVGrid (columns: columns, spacing: 8){
                    ForEach(vm.userPosts) { post in
                        TinyPostView(post: post, width: nil, height: 180)
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
                .padding(.top, 8)
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
            if vm.sectionLoading == "comments" {
                ProgressView()
                    .padding(.top, 40)
            }
            if !vm.userComments.isEmpty {
                VStack {
                    ForEach(vm.userComments) { comment in
                        HStack(spacing: 0){
                            VStack {
                                Spacer()
                                ProfilePic(address: chosenProfileImageAddress, size: 30)
                                    .padding(.leading, 4)
                            }
                            VStack(alignment: .leading, spacing: 0){
                                HStack {
                                    Spacer()
                                    Text(username)
                                    Image(systemName: "arrow.right")
                                }
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.theme.darkBlue)
                                .padding(.horizontal)
                                .onTapGesture {
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

//                                    } else {
////                                        Task {
////                                            let event = try await eventViewModel.fetchEvent(eventId: comment.postId)
////                                            eventViewModel.setEvent(event: event)
////                                            withAnimation(.easeInOut(duration: 0.2)) {
////                                                showEventView = true
////                                            }
////                                            eventViewModel.commentsIsLoading = true
////                                            try await eventViewModel.fetchComments()
////                                            eventViewModel.commentsIsLoading = false
////                                        }
//                                    }
                                }
                                Text(vm.formatFirestoreDate(comment.createdAt))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.lightGray)
                                    .padding(.leading, 24)
                                    .offset(y: 10)
                                MiniCommentView(comment: comment)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical)
                        if vm.userComments.last?.id != comment.id {
                            Divider()
                        }
                    }
                }
                .padding(.top, 8)
            }
            else {
                ZStack {
                    Color.theme.background
                    VStack {
                        Image(systemName: "ellipsis.message")
                            .frame(width: 100, height: 100)
                        Text("No comments yet...")
                            .font(.title3)
                    }
                    .padding(.top, 40)
                }
            }
        }
        .padding(.bottom, 45)
        .task {
            Task {
                vm.sectionLoading = "comments"
                try await vm.getCommentsIfNeeded()
                print("Fetching Comments")
                vm.sectionLoading = ""
            }
        }
        .refreshable {
            Task {
                try await vm.getMoreUserComments()
            }
        }
        .ignoresSafeArea()
    }
    
    var pollSection: some View {
        ZStack {
            Color.theme.background
            ScrollView {
                if vm.sectionLoading == "polls" {
                    ProgressView()
                        .padding(.top, 40)
                }
                if vm.userEvents.isEmpty {
                    VStack {
                        Image(systemName: "chart.bar.horizontal.page")
                            .frame(width: 100, height: 100)
                        Text("No Polls Yet")
                            .font(.title3)
                    }
                    .padding(.top, 40)
                }
                else {
                    VStack (spacing: 8){
//                        ForEach(vm.userPolls) { poll in
//
//                        }
                    }
                    .padding(.top, 8)
                }
            }
            .task {
                Task {
                    vm.sectionLoading = "polls"
//                    try await vm.getUserEventsIfNeeded()
                    print("USEREVENTS", vm.userEvents)
                    vm.sectionLoading = ""
                }
            }
            .refreshable {
                Task {
                    vm.sectionLoading = "polls"
//                    try await vm.getMoreUserEvents()
                    print("USEREVENTS", vm.userEvents)
                    vm.sectionLoading = ""
                }
            }
        }
    }
    
    var savedSection: some View {
        ScrollView {
            VStack(alignment: .leading){
                if !(vm.savedEvents.isEmpty && vm.savedPosts.isEmpty) {
                    HStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .onTapGesture {
                                showSearchSheet = true
                            }
                    }
                }
                if vm.savedPosts.isEmpty && vm.savedEvents.isEmpty {
                    VStack {
                        Image(systemName: "bookmark")
                            .frame(width: 100, height: 100)
                        Text("No saved posts or events yet...")
                            .font(.title3)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                if !vm.savedPosts.isEmpty {
                    Text("Posts")
                        .font(.headline)
                }
                LazyVGrid (columns: [GridItem(.flexible(), spacing: 8),GridItem(.flexible(), spacing: 8)], spacing: 8){
                    ForEach(vm.savedPosts) { post in
                        MiniPostView(post: post, width: nil, stroked: nil)
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
                .padding(.top, 8)
                if !vm.savedEvents.isEmpty {
                    Text("Events")
                        .font(.headline)
                        .padding(.top, 8)
                }
                VStack (spacing: 8){
                    ForEach(vm.savedEvents) { event in
//                        MiniEventView(event: event)
//                            .onTapGesture {
//                                eventViewModel.setEvent(event: event)
//                                showEventView = true
//                                Task {
//                                    eventViewModel.commentsIsLoading = true
//                                    try await eventViewModel.fetchComments()
//                                    eventViewModel.commentsIsLoading = false
//                                }
//                            }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
            .padding(.bottom, 48)
        }
        .refreshable {
            Task {
                try await vm.getSavedPosts()
            }
        }
        .task {
            Task {
                try await vm.getSavedPosts()
            }
        }
    }
    
    var upvotedSection: some View {
        ScrollView {
            if vm.sectionLoading == "upvoted" {
                ProgressView()
                    .padding(.top, 40)
            }
            if vm.upvotedPosts.isEmpty {
                ZStack {
                    Color.theme.background
                    VStack {
                        Image(systemName: "chevron.up")
                            .frame(width: 100, height: 100)
                        Text("Haven't seen anything you like?")
                            .font(.title3)
                    }
                    .padding(.top, 40)
                }
            }
            else {
                LazyVGrid (columns: columns, spacing: 8){
                    ForEach(vm.upvotedPosts) { post in
                        TinyPostView(post: post, width: nil, height: 180)
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
                .padding(.top, 8)
            }
        }
        .refreshable {
            vm.getMoreUpvotedPosts()
        }
        .task {
            vm.getMoreUpvotedPosts()
        }
    }
    
    var sectionPicker: some View {
        ScrollView (.horizontal, showsIndicators: false) {
            HStack(spacing: UIScreen.main.bounds.width / 20){
                ForEach(topTabs, id: \.self) { tab in
                    VStack(spacing: 0){
                        Text(tab.title)
                            .padding(.bottom, 4)
                        ZStack {
                            if selectedTopTab == tab {
                                Rectangle()
                                    .fill(Color.theme.darkBlue)
                                    .frame(height: 2)
                                    // 👇 Magic line
                                    .matchedGeometryEffect(id: "underline", in: animation)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                    .onTapGesture {
                        previousTabIndex = currentIndex
                        currentIndex = topTabs.firstIndex(of: tab)!
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTopTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
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
                    Color.theme.background
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
    
    @State var columns: [GridItem] = []
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: - Header
                HStack {
                    Button(action: { showImageOverlay = false }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.theme.darkBlue)
                            .font(.title2)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text("Change Profile Image")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .opacity(0)
                            .padding()
                    }
                }
                .padding(.top, 12)
                
                Spacer()
                
                VStack {
                    // MARK: - Selected Image Preview
                    ProfilePic(address: newChosenAddress ?? imageAddress, size: 200)
                        .padding(.bottom, 24)
                    
                    HStack {
                        Spacer()
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(addresses, id: \.self) { address in
                                ProfilePic(address: address, size: 75)
                                    .opacity(newChosenAddress == address ? 0.6 : 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(newChosenAddress == address ? Color.theme.darkBlue : .clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        newChosenAddress = address
                                    }
                            }
                        }
                        .fixedSize()
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
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(newChosenAddress == nil)
                
            }
            .padding(.horizontal)
        }
        .onAppear {
            for _ in addresses {
                columns.append(GridItem(.adaptive(minimum: 70), spacing: 16))
            }
        }
    }
}




