//
//  PostView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/7/25.
//

import SwiftUI
import Kingfisher

struct PostView: View {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("isAdmin") var isAdmin = false
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress: String = ""
    @AppStorage("username") var username = ""
    
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var addPostViewModel: AddPostViewModel
    @EnvironmentObject var windowSize: WindowSize
    
    @Environment(\.colorScheme) var scheme
    
    @State private var profileTask: Task<Void, Never>?
    
    @FocusState var isCommentTextFieldFocused: Bool
    
    @Binding var showPostView: Bool
    @Binding var showSearchView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showAddPostView: Bool
    @Binding var showPollView: Bool
    @Binding var showProfileView: Bool
    @Binding var showReportSheet: Bool
    @Binding var preReportInfo: preReportModel?
    
    @State var commentText: String = ""
    @State var shiftScroll: Bool = false
    @State private var textEditorHeight: CGFloat = 36
    @State var parentId: String? = nil
    @State var parentAuthorName: String? = nil
    @State var parentAuthorId: String? = nil
    @State var ancestorCommentId: String? = nil
    @State var highlightedCommentId: String? = nil
    @State var showOptionsSheet: Bool = false
    @State var selectedItemForOptions: GenericItem? = nil
    @State var showProfilePopup: Bool = false
    @State var userForDisplay: UserModel? = nil
    @State var thingHeldId: String = ""
    @State var isNamePressed: Bool = false
    @State var isCommentTextFieldFocusedState: Bool = false
    @State var voteInFlight: Bool = false
    
    @Namespace var commentBubbles
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            if let post = postViewModel.post {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            VStack(spacing: -12){
                                ZStack {
                                    postImage(url: post.imageUrl, maxHeight: 400)
                                        .cornerRadius(30)
                                        .padding(.horizontal)
                                        .padding(.top, 12)
                                        .onTapGesture {
                                            UIApplication.shared.endEditing()
                                        }
                                }
                                
                                postInfo(for: post)
                                    .padding(.horizontal)
                                    .padding(.bottom)
                                    .id("postTop")
                                    .padding(.bottom, 4)
                            }
                            
                            Text("Comments")
                                .font(.headline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            commentSection
                                .id("commentSectionBottom")
                                .padding(.bottom, 56)
                                .padding()
                            
                        }
                        .padding(.vertical, 55)
                    }
                    .refreshable {
                        Task {
                            CommentsCache.shared.clearPost(postId: post.id)
                            try await postViewModel.loadInitialRootComments()
                        }
                    }
                    .onScrollPhaseChange { oldPhase, newPhase in
                        if newPhase == .interacting {
                            UIApplication.shared.endEditing()
                        }
                    }
                    .onChange(of: highlightedCommentId) {
                        if let id = highlightedCommentId {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo("\(id)", anchor: .center)
                            }
                            print("Scrolling too")
                        }
                    }
                    .onChange(of: isCommentTextFieldFocused) {
                        if highlightedCommentId == nil {
                            if isCommentTextFieldFocused == true {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("postTop", anchor: .center)
                                }
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 80 { // left swipe
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPostView = false
                                    postViewModel.rootComments = []
                                }
                            }
                        }
                )
            }
            
            VStack(spacing: 0){
                ZStack {
                    VStack {
                        BackgroundHelper.shared.appleHeaderBlur.frame(height: 88)
                        Spacer()
                    }
                    VStack {
                        header
                            .frame(height: 55)
                        Spacer()
                    }
                }
                Spacer()
                ZStack {
                    // Full-screen background that aligns the gradient to the bottom
                    VStack {
                        Spacer()
                        BackgroundHelper.shared.appleFooterBlur.frame(height: 110)
                    }
                    .ignoresSafeArea()
                    VStack {
                        Spacer()
                        commentBar
                            .focused($isCommentTextFieldFocused)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showProfilePopup)
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(parentPostId: postViewModel.post?.id, selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView, showPollView: $showPollView,  showReportSheet: $showReportSheet, preReportInfo: $preReportInfo, screenType: .pollsFeed)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThickMaterial) // or .regularMaterial
                .background(Color.black.opacity(1)) // makes it darker
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack(spacing: 4) {
                // Left column: fixed width matching the right-side width
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                UIApplication.shared.endEditing()
                                showPostView = false
                                hideTabBar = false
                                postViewModel.rootComments = []
                            }
                        }
                    Spacer(minLength: 0)
                }
                .frame(width: 98)

                // Center column: truly centered content
                VStack {
                    Text(postViewModel.post?.name ?? "Name")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
                    Text(postViewModel.postCities.enumerated().map { index, city in
                        let part = "\(city.city), \(city.state_id.uppercased())"
                        if postViewModel.postCities.count > 1 && index == 0 {
                            return part + " &"
                        } else {
                            return part
                        }
                    }.joined(separator: " "))
                    .italic(true)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.trashcanGray)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Right column: fixed width matching the left-side width
                HStack {
                    Spacer(minLength: 0)
                    Image(systemName: "chart.bar.horizontal.page")
                        .font(.title3)
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAddPostView = true
                                addPostViewModel.currentNewContent = .poll
                                addPostViewModel.linkedPost = postViewModel.post
                            }
                        }
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .onTapGesture {
                            if let post = postViewModel.post {
                                selectedItemForOptions = GenericItem.post(post)
                                showOptionsSheet = true
                                preReportInfo = preReportModel(contentType: .post, contentId: post.id, contentAuthorId: post.authorId, reportAuthorId: userId)
                            }
                        }
                }
                .frame(width: 98)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
    }
    
    @ViewBuilder
    func commentRow(com: viewCommentModel, ancestorId: String, isRoot: Bool) -> some View  {
        LazyVStack {
            HStack(alignment: .top) {
                HStack(alignment: .top){
                    ProfilePic(address: com.comment.authorId == userId ? chosenProfileImageAddress : com.comment.authorProfPic, size: 25)
                        .scaleEffect(thingHeldId == com.id ? 0.9 : 1)
//                        .onLongPressGesture {
//                            profileTask?.cancel()
//
//                            profileTask = Task {
//                                async let skeletonDelay: Void = {
//                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
//                                    await MainActor.run { showProfilePopup = true }
//                                }()
//                                let author = try? await postViewModel.fetchPostAuthor(authorId: com.comment.authorId)
//                                await MainActor.run {
//                                    withAnimation(.easeInOut(duration: 0.2)) { userForDisplay = author }
//                                }
//                            }
//                        }

                    VStack(alignment: .leading){
                        HStack {
                            Text(com.comment.authorId == userId ? username : com.comment.authorName)
                                .font(.caption)
                                .scaleEffect(thingHeldId == com.id ? 0.9 : 1)
//                                .onLongPressGesture {
//                                    profileTask?.cancel()
//                                    profileTask = Task {
//                                        async let skeletonDelay: Void = {
//                                            try? await Task.sleep(nanoseconds: 1_500_000_000)
//                                            await MainActor.run { showProfilePopup = true }
//                                        }()
//                                        let author = try? await postViewModel.fetchPostAuthor(authorId: com.comment.authorId)
//                                        await MainActor.run {
//                                            withAnimation(.easeInOut(duration: 0.2)) { userForDisplay = author }
//                                        }
//                                    }
//                                }

                            Text(postViewModel.timeAgoString(from: com.comment.createdAt))
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                        }
                        .padding(.bottom, 4)
                        (Text(com.comment.isGrand
                              ? "@\(com.comment.parentAuthorName) "
                              : "").foregroundStyle(Color.blue).font(.subheadline))
                        + Text(com.comment.message)
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                        HStack {
                            Image(systemName: "message")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(Color.theme.accent)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    parentId = com.id
                                    parentAuthorName = com.comment.authorName
                                    parentAuthorId = com.comment.authorId
                                    isCommentTextFieldFocused = true
                                    ancestorCommentId = ancestorId
                                    highlightedCommentId = com.id
                                }
                                .padding(.trailing, 8)
                            Image(systemName: "flag")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(Color.theme.accent)
                                .padding(.trailing, 8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    preReportInfo = preReportModel(contentType: .comment, contentId: com.comment.id, contentAuthorId: com.comment.authorId, reportAuthorId: userId)
                                    showReportSheet = true
                                }
                            if com.comment.authorId == profileViewModel.userId || isAdmin {
                                Image("ellipses")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(Color.theme.accent)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedItemForOptions = GenericItem.comment(com.comment)
                                        showOptionsSheet = true
                                        preReportInfo = preReportModel(contentType: .comment, contentId: com.id, contentAuthorId: com.comment.authorId, reportAuthorId: userId)
                                    }
                            }
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
                Spacer()
                VStack {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(postViewModel.upvotedComms.contains(com.id) ? Color.theme.darkBlue : .gray)
                        .frame(width: 12, height: 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if postViewModel.upvotedComms.contains(com.id) { postViewModel.removeComUpvote(comId: com.id, ancestorId: ancestorId, isRoot: isRoot) }
                            else { postViewModel.upvoteCom(comId: com.id, ancestorId: ancestorId, isRoot: isRoot) }
                        }
                        .padding(.bottom, 8)
                    Text("\(com.comment.upvotes)")
                        .font(.caption)
                        .contentTransition(.numericText())
                }
                .padding(.top, 8)
            }
            .padding(12)
        }
    }
    
    var commentSection: some View {
        LazyVStack {
            ForEach(postViewModel.rootComments, id: \.comment.id) { parent in
                LazyVStack {
                    commentRow(com: parent, ancestorId: parent.id, isRoot: true)
                    if parent.comment.hasChildren {
                        if let threadState = parent.commentThreadState {
                            if threadState.isExpanded == true {
                                ForEach(threadState.children) { child in
                                    HStack(alignment: .top){
                                        Rectangle()
                                            .frame(width: 20, height: 1)
                                            .padding(.top)
                                        commentRow(com: child, ancestorId: parent.id, isRoot: false)
                                            .id(child.id)
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    if (parent.commentThreadState?.isExpanded == false) || parent.commentThreadState?.hasMore == true || (parent.comment.hasChildren && parent.commentThreadState?.children.isEmpty == true)  {
                        HStack {
                            Rectangle()
                                .fill(Color.theme.gray)
                                .frame(width: 14, height: 0.5)
                            Text("View Replies")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            Rectangle()
                                .fill(Color.theme.gray)
                                .frame(width: 20, height: 0.5)
                        }
                        .onTapGesture {
                            Task {
                                try await postViewModel.fetchChildren(rootComment: parent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                    }

                }
                .padding(8)
                .glassEffect(in: .rect(cornerRadius: 30))
//                .glassEffectUnion(id: "thread-\(postViewModel.findGrandparent(comment: com))", namespace: commentBubbles)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
                .padding(.top, 16)
                .transition(.opacity)
                .onAppear {
                    if parent.id == postViewModel.rootComments.last?.id && postViewModel.hasMoreComments == true {
                        Task {
                            print("has more?")
                            try await postViewModel.fetchRootComments()
                        }
                    }
                }
                .id(parent.id)
            }
            if postViewModel.commentsIsLoading {
                ProgressView()
                    .padding(32)
            }
            else if postViewModel.rootComments.count == 0 {
                Text("No comments yet")
                    .padding(.top, 32)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
    
    var commentBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Larger profile pic inline with the input
                VStack {
                    Spacer()
                    ProfilePic(address: chosenProfileImageAddress, size: 44)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showProfileView = true
                                showPostView = false
                            }
                        }
                }
                .padding(.bottom, 2)
                
                // Rounded search-like input with embedded send button
                VStack(spacing: 4){
                    Spacer()
                    if let parentAuthorName = parentAuthorName {
                        HStack(spacing: 0){
                            Spacer()
                            Text("replying to")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("@\(parentAuthorName)")
                                .font(.caption)
                                .foregroundStyle(Color.theme.lightBlue)
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.parentAuthorName = nil
                                    parentAuthorId = nil
                                    parentId = nil
                                    highlightedCommentId = nil
                                    parentAuthorId = nil
                                    ancestorCommentId = nil
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        UIApplication.shared.endEditing()
                                    }
                                }
                            Spacer()
                        }
                        .padding(.trailing, 4)
                    }
                    HStack(spacing: 8) {
                        TextField("Add a comment...", text: $commentText, axis: .vertical)
                            .focused($isCommentTextFieldFocused)
                            .padding(14)
                            .font(.subheadline)
                            .lineLimit(4)
                        // Send icon inside the field area
                        Button(action: {
                            if !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                submitComment()
                                highlightedCommentId = nil
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.theme.gray : Color.theme.darkBlue
                                )
                                .opacity(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal)
                    }
                    .contentShape(Rectangle())
                    .glassEffect()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    @ViewBuilder
    private func postInfo(for post: PostModel) -> some View {
        VStack {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    ProfilePic(address: post.authorId == userId ? chosenProfileImageAddress : post.authorPicUrl, size: 25)
                    Text(post.authorId == userId ? username : post.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
                }
                VStack(alignment: .leading) {
                    Text(postViewModel.timeAgoString(from: post.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack {
                    Text("\(post.upvotes)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Image(systemName: "arrow.up.circle")
                        .foregroundStyle(postViewModel.userUpvoted ? Color.theme.darkBlue : Color.theme.lightGray)
                        .font(.title)
                        .onTapGesture {
                            guard !voteInFlight else { return }
                            voteInFlight = true

                            // Snapshot
                            let wasUpvoted = postViewModel.userUpvoted
                            let wasDownvoted = postViewModel.userDownvoted

                            // Optimistic UI
                            if !(wasUpvoted || wasDownvoted) {
                                postViewModel.userUpvoted = true
                            } else if wasUpvoted {
                                postViewModel.userUpvoted = false
                            }

                            Task {
                                defer { voteInFlight = false }

                                do {
                                    if !(wasUpvoted || wasDownvoted) {
                                        try await postViewModel.upvote(post: post)
                                        homeViewModel.upvotePost(post: post)
                                    } else if wasUpvoted {
                                        try await postViewModel.removeUpvote(post: post)
                                        homeViewModel.removeUpvote(post: post)
                                    }
                                } catch {
                                    // Rollback
                                    postViewModel.userUpvoted = wasUpvoted
                                    postViewModel.userDownvoted = wasDownvoted
                                }
                            }
                        }

                }
                .animation(.easeInOut(duration: 0.3), value: post.upvotes)
                HStack {
                    Text("\(post.downvotes)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(postViewModel.userDownvoted ? Color.theme.darkRed : Color.theme.lightGray)
                        .font(.title)
                        .onTapGesture {
                            guard !voteInFlight else { return }
                            voteInFlight = true

                            // Snapshot
                            let wasUpvoted = postViewModel.userUpvoted
                            let wasDownvoted = postViewModel.userDownvoted

                            // Optimistic UI
                            if !(wasUpvoted || wasDownvoted) {
                                postViewModel.userDownvoted = true
                            } else if wasDownvoted {
                                postViewModel.userDownvoted = false
                            }

                            Task {
                                defer { voteInFlight = false }

                                do {
                                    if !(wasUpvoted || wasDownvoted) {
                                        try await postViewModel.downvote(post: post)
                                        homeViewModel.downvotePost(post: post)
                                    } else if wasDownvoted {
                                        try await postViewModel.removeDownvote(post: post)
                                        homeViewModel.removeDownvote(post: post)
                                    }
                                } catch {
                                    // Rollback
                                    postViewModel.userUpvoted = wasUpvoted
                                    postViewModel.userDownvoted = wasDownvoted
                                }
                            }
                        }
                }
                .animation(.easeInOut(duration: 0.3), value: post.downvotes)
            }// hstack
            .animation(.easeInOut(duration: 0.3), value: postViewModel.userUpvoted)
            .animation(.easeInOut(duration: 0.3), value: postViewModel.userDownvoted)
            InlineExpandableText(text: post.text, limit: 200, font: .body)
                .padding(.top, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !post.tags.isEmpty {
                // Tags grid styled like AddPostView: blue capsules with # prefix
                let columns = [GridItem(.adaptive(minimum: 80), spacing: 8, alignment: .leading)]
                VStack {
                    FlowLayout {
                        ForEach(post.tags, id: \.self) { tag in
                            TagPill(title: tag, isSelected: true, color: Color.theme.darkBlue)
                        }
                    }
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
        }
        .padding()
        .background(Material.thin.opacity(0.3))
        .cornerRadius(30)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
    
    func submitComment() {
        if commentText != "" {
            print("submitting with parent comment author: ", parentAuthorId as Any)
            var tempText = commentText
            var tempAuthorName = parentAuthorName
            withAnimation(.easeInOut(duration: 0.2)) {
                isCommentTextFieldFocused = false
                UIApplication.shared.endEditing()
                parentAuthorName = nil
                commentText = ""
            }
            Task {
                print("uploading from post")
                try await postViewModel.uploadComment(message: tempText, parentId: parentId, parentAuthorId: parentAuthorId, parentAuthorName: tempAuthorName, ancestorId: ancestorCommentId)
                parentAuthorId = nil
                ancestorCommentId = nil
                parentId = nil
            }
        }
    }
    
    func setParentStates(parentId: String?, parentAuthorId: String?, parentAuthorName: String?, ancestorCommentId: String?) {
        self.parentId = parentId
        self.parentAuthorId = parentAuthorId
        self.parentAuthorName = parentAuthorName
        self.ancestorCommentId = ancestorCommentId
    }
}

