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
    
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    
    @Binding var selectedTab: TabBarItem
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showEventView: Bool
    @Binding var showSettingsView: Bool
    
    @State var showSearchSheet: Bool = false
    @State private var previousTabIndex: Int = 0
    @State var showImageOverlay: Bool = false
    @Namespace private var animation
    
    let topTabs: [TopTab] = [TopTab(title: "Posts"), TopTab(title: "Comments"), TopTab(title: "Events"), TopTab(title: "Saved"), TopTab(title: "Cities"), TopTab(title: "Achievements")]
    
    @State var currentIndex: Int = 0
    
    @State var selectedTopTab: TopTab = TopTab(title: "Posts")
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
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
        }
        .task {
            Task {
                vm.sectionLoading = "posts"
                try await vm.getUserPostsIfNeeded()
                try await vm.loadUserInfo()
                vm.sectionLoading = ""
                vm.getParams()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        selectedTab = TabBarItem(iconName: "EventsIcon", title: "Events")
                    }
                }
        )
        .sheet(isPresented: $showSearchSheet) {
            searchSavedView(selectedPost: $selectedPost, showPostView: $showPostView, hideTabBar: $hideTabBar, showEventView: $hideTabBar, showSearchSheet: $showSearchSheet)
        }
        if showImageOverlay {
            profileImageOverlay(url: vm.profImageUrl, showImageOverlay: $showImageOverlay, hideTabBar: $hideTabBar, namespace: animation)
                .transition(.opacity)
        }
    }
    
    var profileInfo: some View {
        VStack(spacing: 0){
            HStack {
                Text("@\(vm.username)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "gear")
                    .font(.title2)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hideTabBar = true
                            showSettingsView = true
                        }
                    }
            }
            Spacer()
            HStack {
                if !showImageOverlay {
                    ZStack {
                        profileImageClip(url: vm.profImageUrl, height: 130, params: vm.profPicParams ?? ProfPicParams(offsetX: 0, offsetY: 0, scale: 1))
                    }
                    .frame(width: 130, height: 130)
                    .matchedGeometryEffect(id: "profPic", in: animation, isSource: true)
                    .modifier(Pressable(onPress: {
                        hideTabBar = true
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showImageOverlay = true
                        }
                    }))
                }
                else {
                    Circle()
                        .fill(Color.theme.background)
                        .frame(width: 130)
                }
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
                                    hideTabBar = true
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
                                profileImageClip(url: vm.profImageUrl, height: 20, params: vm.profPicParams ?? ProfPicParams(offsetX: 0, offsetY: 0, scale: 1))
                            }
                            VStack(alignment: .leading, spacing: 0){
                                HStack {
                                    Spacer()
                                    Text(comment.authorName)
                                    Image(systemName: "arrow.right")
                                }
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.theme.darkBlue)
                                .padding(.horizontal)
                                .onTapGesture {
                                    if !comment.isOnEvent {
                                        Task {
                                            let post = try await postViewModel.fetchPost(postId: comment.postId)
                                            selectedPost = post
                                            postViewModel.setPost(postSelection: post)
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showPostView = true
                                                hideTabBar = true
                                            }
                                            postViewModel.commentsIsLoading = true
                                            try await postViewModel.fetchComments()
                                            postViewModel.commentsIsLoading = false
                                        }

                                    } else {
                                        Task {
                                            let event = try await eventViewModel.fetchEvent(eventId: comment.postId)
                                            eventViewModel.setEvent(event: event)
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                hideTabBar = true
                                                showEventView = true
                                            }
                                            eventViewModel.commentsIsLoading = true
                                            try await eventViewModel.fetchComments()
                                            eventViewModel.commentsIsLoading = false
                                        }
                                    }
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
    }
    
    var eventSection: some View {
        ZStack {
            Color.theme.background
            ScrollView {
                if vm.sectionLoading == "events" {
                    ProgressView()
                        .padding(.top, 40)
                }
                if vm.userEvents.isEmpty {
                    VStack {
                        Image(systemName: "calendar.badge.plus")
                            .frame(width: 100, height: 100)
                        Text("No Events Yet")
                            .font(.title3)
                    }
                    .padding(.top, 40)
                }
                else {
                    VStack (spacing: 8){
                        ForEach(vm.userEvents) { event in
                            MiniEventView(event: event)
                                .onTapGesture {
                                    eventViewModel.setEvent(event: event)
                                    hideTabBar = true
                                    showEventView = true
                                    Task {
                                        eventViewModel.commentsIsLoading = true
                                        try await eventViewModel.fetchComments()
                                        eventViewModel.commentsIsLoading = false
                                    }
                                }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .task {
                Task {
                    vm.sectionLoading = "events"
                    try await vm.getUserEventsIfNeeded()
                    print("USEREVENTS", vm.userEvents)
                    vm.sectionLoading = ""
                }
            }
            .refreshable {
                Task {
                    vm.sectionLoading = "events"
                    try await vm.getMoreUserEvents()
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
                        MiniPostView(post: post, width: nil)
                            .onTapGesture {
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
                }
                .padding(.top, 8)
                if !vm.savedEvents.isEmpty {
                    Text("Events")
                        .font(.headline)
                        .padding(.top, 8)
                }
                VStack (spacing: 8){
                    ForEach(vm.savedEvents) { event in
                        MiniEventView(event: event)
                            .onTapGesture {
                                eventViewModel.setEvent(event: event)
                                hideTabBar = true
                                showEventView = true
                                Task {
                                    eventViewModel.commentsIsLoading = true
                                    try await eventViewModel.fetchComments()
                                    eventViewModel.commentsIsLoading = false
                                }
                            }
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
    
    var sectionPicker: some View {
        ScrollView (.horizontal, showsIndicators: false) {
            HStack(spacing: 20){
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
                case "Events":
                    eventSection
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

#Preview {
    ProfileView(selectedTab: .constant(TabBarItem(iconName: "ProfileIcon", title: "Profile")), selectedPost: .constant(nil), showPostView: .constant(false), hideTabBar: .constant(false), showEventView: .constant(false), showSettingsView: .constant(false))
}

struct searchSavedView: View {
    
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var eventViewModel: EventViewModel

    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showEventView: Bool
    
    @Binding var showSearchSheet: Bool
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                header
                resultsSection
            }
        }
        .task {
            isFocused = true
            profileViewModel.getSearchedPosts()
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .onTapGesture {
                        print("CHEV TAPPED")
                        isFocused = false
                        showSearchSheet = false
                    }
                    .padding(.trailing, 8)
                TextField("Search saved...", text: $profileViewModel.searchText)
                    .focused($isFocused)
                    .padding(8)
                    .background(Color.theme.lightGray.cornerRadius(5))
                
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()
        }
        .background(Color.theme.background)
    }
    
    var resultsSection: some View {
        VStack(spacing: 0) {
            if profileViewModel.searchResults.isEmpty {
                Text("No results found")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            else {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                    // Create groups of 3 items: 2 small posts + 1 big event
                    let grouped = stride(from: 0, to: profileViewModel.searchResults.count, by: 3).map {
                        Array(profileViewModel.searchResults[$0..<min($0 + 3, profileViewModel.searchResults.count)])
                    }

                    ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                        // First row — two small posts if available
                        GridRow {
                            if group.count > 0 {
                                mixedCell(group[0])
                            }
                            if group.count > 1 {
                                mixedCell(group[1])
                            }
                        }

                        // Second row — the event (or big item) if available
                        if group.count > 2 {
                            GridRow {
                                mixedCell(group[2])
                                    .gridCellColumns(2)
                            }
                        }
                    }
                }            }
        }
        .padding()
    }
    
    @ViewBuilder
    func mixedCell(_ mixed: MixedType) -> some View {
        switch mixed {
        case .post(let post):
            TinyPostView(post: post, width: UIScreen.main.bounds.width / 2, height: 180)
                .onTapGesture {
                    selectedPost = post
                    postViewModel.setPost(postSelection: post)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchSheet = false
                        showPostView = true
                        hideTabBar = true
                    }
                    Task {
                        postViewModel.commentsIsLoading = true
                        try await postViewModel.fetchComments()
                        postViewModel.commentsIsLoading = false
                    }
                }
        case .event(let event):
            MiniEventView(event: event)
                .onTapGesture {
                    eventViewModel.setEvent(event: event)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchSheet = false
                        hideTabBar = true
                        showEventView = true
                    }
                    Task {
                        eventViewModel.commentsIsLoading = true
                        try await eventViewModel.fetchComments()
                        eventViewModel.commentsIsLoading = false
                    }
                }
        }
    }

}

struct profileImageOverlay: View {
    
    let url: String
    @Binding var showImageOverlay: Bool
    @Binding var hideTabBar: Bool
    @State var showImageOptions: Bool = false
    @State var pickedImage: UIImage? = nil
    @State var showCropper: Bool = false
    @State var imageSelection: PhotosPickerItem? = nil
    
    let namespace: Namespace.ID
    
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    if !showImageOptions {
                        hideTabBar = false
                        showImageOverlay = false
                    }
                    else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showImageOptions = false
                        }
                    }
                }
            VStack {
                if showImageOptions {
                    choicesBox
                        .opacity(0)
                        .padding(.bottom)
                        .allowsHitTesting(false)
                }
                ZStack {
                    profileImageClip(url: url, height: 225, params: profileViewModel.profPicParams ?? ProfPicParams(offsetX: 0, offsetY: 0, scale: 1))
                }
                .frame(width: 225, height: 225)
                .matchedGeometryEffect(id: "profPic", in: namespace, isSource: false)
                .overlay (
                    Circle()
                        .frame(width: 40)
                        .foregroundColor(.white)
                        .overlay (
                            Image(systemName: "pencil")
                                .font(.body)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showImageOptions = true
                            }
                        }
                        .opacity(showImageOptions ? 0 : 1)
                    , alignment: .bottomTrailing
                )
                if showImageOptions {
                    choicesBox
                        .padding(.top)
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 180)
            if !showImageOptions {
                VStack {
                    Spacer()
                    HStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50)
                            .overlay(
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body)
                            )
                        Spacer()
                    }
                    .frame(height: 50)
                    .padding()
                    .opacity(0)
                }
            }
            if showCropper {
                if pickedImage != nil {
                    PhotoCropperView(pickedImage: $pickedImage, showImageOverlay: $showImageOverlay, hideTabBar: $hideTabBar)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
    
    var choicesBox: some View {
        VStack(spacing: 20){
            PhotosPicker(selection: $imageSelection, matching: .any(of: [.images])) {
                HStack {
                    Text("Choose from library")
                    Spacer()
                    Image(systemName: "photo")
                }
                .accentColor(Color.theme.accent)
                .background(Color.theme.background)
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: imageSelection) { newSelection in
                guard let newSelection else { return }
                print("onChange fired")
                Task {
                    if let data = try? await newSelection.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedImage = uiImage
                        showCropper = true
                        print("Show cropper:", showCropper)
                    }
                }
            }
            HStack {
                Text("Delete")
                    .foregroundStyle(Color.theme.darkRed)
                Spacer()
                Image(systemName: "trash")
                    .foregroundStyle(Color.theme.darkRed)
            }
            .onTapGesture {
                Task {
                    try await profileViewModel.deleteProfilePic(ogImageUrl: profileViewModel.profImageUrl)
                    profileViewModel.profImageUrl = ""
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showImageOverlay = false
                    }
                }
            }
        }
        .font(.body)
        .padding()
        .background(Color.theme.background.cornerRadius(15).shadow(color: Color.black.opacity(0.2), radius: 5))
        .frame(width: 250)

    }
}

struct PhotoCropperView: View {
    
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State var isLoading: Bool = false
    @GestureState private var gestureScale: CGFloat = 1.0
    
    @Binding var pickedImage: UIImage?
    @Binding var showImageOverlay: Bool
    @Binding var hideTabBar: Bool

    var body: some View {
        ZStack {
            // Dim background for modal look
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                let cropSize = 300.0
                let radius = cropSize / 2
                let totalScale = max(1.0, min(scale * gestureScale, 4.0)) // 👈 enforce scale live

                if let image = pickedImage {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cropSize, height: cropSize)
                            .scaleEffect(totalScale)
                            .offset(
                                x: clampedOffset(
                                    value: offset.width + dragOffset.width,
                                    cropSize: cropSize,
                                    radius: radius,
                                    scale: totalScale
                                ),
                                y: clampedOffset(
                                    value: offset.height + dragOffset.height,
                                    cropSize: cropSize,
                                    radius: radius,
                                    scale: totalScale
                                )
                            )
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = value.translation
                                    }
                                    .onEnded { value in
                                        offset.width = clampedOffset(
                                            value: offset.width + value.translation.width,
                                            cropSize: cropSize,
                                            radius: radius,
                                            scale: totalScale
                                        )
                                        offset.height = clampedOffset(
                                            value: offset.height + value.translation.height,
                                            cropSize: cropSize,
                                            radius: radius,
                                            scale: totalScale
                                        )
                                        print("WIDTH: ", offset.width, "HEIGHT: ", offset.height)
                                        print("CROP SIZE: ", cropSize)
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .updating($gestureScale) { value, state, _ in
                                        // 👇 Live clamp — stops shrinking past 1× while pinching
                                        state = max(1.0 / scale, min(value, 4.0 / scale))
                                    }
                                    .onEnded { value in
                                        // Final clamp on gesture end
                                        scale = max(1.0, min(scale * value, 4.0))
                                        print("TOTAL SCALE", totalScale)
                                    }
                            )
                            .animation(.easeInOut(duration: 0.2), value: totalScale)
                            .frame(width: cropSize, height: cropSize)
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                }
            }
            .padding(.bottom, 64)

            VStack {
                HStack {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .onTapGesture {
                            pickedImage = nil
                        }
                    Spacer()
                }
                .padding(.top, 48)
                .padding(.horizontal)
                Spacer()
                if !isLoading {
                    Text("Save")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.darkBlue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding()
                        .padding(.bottom)
                        .onTapGesture {
                            saveCroppedImage()
                        }
                }
                else {
                    ProgressView()
                        .tint(Color.theme.white)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.darkBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding()
                        .padding(.bottom)
                }
            }
            .padding()
        }
    }

    // MARK: - Bound checking
    private func clampedOffset(value: CGFloat, cropSize: CGFloat, radius: CGFloat, scale: CGFloat) -> CGFloat {
        let scaledRadius = radius * scale
        let maxOffset = scaledRadius - radius
        return max(-maxOffset, min(value, maxOffset))
    }

    private func saveCroppedImage() {
        guard let image = pickedImage else { return }

        // Current values
        let totalScale = max(1.0, min(scale * gestureScale, 4.0))
        let offsetX = offset.width + dragOffset.width
        let offsetY = offset.height + dragOffset.height
        
        isLoading = true
        Task {
            let newUrl = try await profileViewModel.uploadNewProfilePicture(image, ogImageUrl: profileViewModel.profImageUrl)
            if let url = newUrl {
                profileViewModel.profImageUrl = url
                print("PROFILE IMAGE", profileViewModel.profImageUrl)
                profileViewModel.saveParams(offsetX: offsetX/300, offsetY: offsetY/300, scale: totalScale)
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                pickedImage = nil
                showImageOverlay = false
            }
            hideTabBar = false
            isLoading = false
        }
        print("✅ Cropped & transformed rectangular image saved.")
    }

}

struct Pressable: ViewModifier {
    @GestureState private var isPressed = false
    let onPress: () -> Void

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .overlay(
                Color.black.opacity(isPressed ? 0.15 : 0)
                    .clipShape(Circle())
            )
            .animation(.easeInOut(duration: 0.125), value: isPressed)
            .gesture(
                LongPressGesture(minimumDuration: 0)
                    .updating($isPressed) { value, state, _ in
                        state = value
                    }
                    .onEnded { _ in
                        onPress()   // 👈 Trigger your function here
                    }
            )
    }
}

