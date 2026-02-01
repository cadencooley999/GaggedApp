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
    
    @State var commentText: String = ""
    @State var shiftScroll: Bool = false
    @State private var textEditorHeight: CGFloat = 36
    @State var parentId: String? = nil
    @State var parentAuthorName: String? = nil
    @State var highlightedCommentId: String? = nil
    @State var showOptionsSheet: Bool = false
    @State var selectedItemForOptions: GenericItem? = nil
    @State var showProfilePopup: Bool = false
    @State var userForDisplay: UserModel? = nil
    @State var thingHeldId: String = ""
    @State var isNamePressed: Bool = false
    @State var isCommentTextFieldFocusedState: Bool = false
    
    @Namespace var commentBubbles
    
    var body: some View {
        ZStack {
            Background()
                .frame(width: windowSize.size.width, height: windowSize.size.height)
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            
            if let post = postViewModel.post {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            VStack(spacing: -12){
                                postImage(url: post.imageUrl, maxHeight: 450)
                                    .cornerRadius(30)
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                    .onTapGesture {
                                        UIApplication.shared.endEditing()
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
                                .padding(.bottom, 32)
                                .padding()
                            
                        }
                        .padding(.vertical, 55)
                    }
                    .refreshable {
                        Task {
                            try await postViewModel.refreshComments()
                        }
                    }
                    .onScrollPhaseChange { oldPhase, newPhase in
                        if newPhase == .interacting {
                            UIApplication.shared.endEditing()
                        }
                    }
                    .onChange(of: highlightedCommentId) {
                        if let id = highlightedCommentId {
                            print(id)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("scrollId-\(id)", anchor: .center)
                            }
                            print("Scrolling too")
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 80 { // left swipe
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPostView = false
                                }
                                postViewModel.comments = []
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
                        BackgroundHelper.shared.appleFooterBlur.frame(height: 100)
                    }
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
            OptionsSheet(parentPostId: postViewModel.post?.id, selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThickMaterial) // or .regularMaterial
                .background(Color.black.opacity(1)) // makes it darker
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
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
                            postViewModel.comments = []
                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack {
                    Text(postViewModel.post?.name ?? "Name")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
                    HStack(spacing: 4) {
                        ForEach(postViewModel.postCities) { city in
                            Text(city.city + ", " + city.state_id.uppercased())
                                .italic(true)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(Color.theme.gray)
                            if postViewModel.postCities.count > 1 {
                                if city == postViewModel.postCities.first! {
                                    Text("&")
                                        .italic(true)
                                        .font(.caption2)
                                        .foregroundStyle(Color.theme.gray)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                GlassEffectContainer {
                    HStack {
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
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
    }
    
    var commentSection: some View {
        LazyVStack(spacing: 0) {
            if postViewModel.commentsIsLoading {
                ProgressView()
                    .padding(.top, 32)
            }
            else {
                if postViewModel.comments.count == 0 {
                    Text("No comments yet")
                        .padding(.top, 32)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                else {
                    GlassEffectContainer {
                        ForEach(postViewModel.comments, id: \.id) { com in
                            let topPadding: CGFloat = com.comment.parentCommentId.isEmpty ? 16 : -16
                            LazyVStack {
                                HStack(alignment: .top) {
                                    HStack(alignment: .top){
                                        if !(com.comment.parentCommentId == "") {
                                            Rectangle()
                                                .fill(Color.theme.gray.opacity(0.5))
                                                .frame(width: 20, height: 2)
                                                .padding(.horizontal, 8)
                                                .padding(.top, 12)
                                                .cornerRadius(5)
                                        }
                                        ProfilePic(address: com.comment.authorId == userId ? chosenProfileImageAddress : com.comment.authorProfPic, size: 25)
                                            .scaleEffect(thingHeldId == com.id ? 0.9 : 1)
                                            .onLongPressGesture {
                                                profileTask?.cancel()
                                                
                                                profileTask = Task {
                                                    async let skeletonDelay: Void = {
                                                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                                                        await MainActor.run { showProfilePopup = true }
                                                    }()
                                                    let author = try? await postViewModel.fetchPostAuthor(authorId: com.comment.authorId)
                                                    await MainActor.run {
                                                        withAnimation(.easeInOut(duration: 0.2)) { userForDisplay = author }
                                                    }
                                                }
                                            }
                                        
                                        VStack(alignment: .leading){
                                            HStack {
                                                Text(com.comment.authorId == userId ? username : com.comment.authorName)
                                                    .font(.caption)
                                                    .scaleEffect(thingHeldId == com.id ? 0.9 : 1)
                                                    .onLongPressGesture {
                                                        profileTask?.cancel()
                                                        profileTask = Task {
                                                            async let skeletonDelay: Void = {
                                                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                                                await MainActor.run { showProfilePopup = true }
                                                            }()
                                                            let author = try? await postViewModel.fetchPostAuthor(authorId: com.comment.authorId)
                                                            await MainActor.run {
                                                                withAnimation(.easeInOut(duration: 0.2)) { userForDisplay = author }
                                                            }
                                                        }
                                                    }
                                                
                                                Text(postViewModel.timeAgoString(from: com.comment.createdAt))
                                                    .font(.caption)
                                                    .foregroundStyle(Color.theme.gray)
                                            }
                                            .padding(.bottom, 4)
                                            (Text(com.isGrandchild
                                                  ? "@\(postViewModel.getAuthorName(id: com.comment.parentCommentId) ?? "") "
                                                  : "").foregroundStyle(Color.blue).font(.subheadline))
                                            + Text(com.comment.message)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.theme.accent)
                                            HStack {
                                                Image(systemName: "message")
                                                    .resizable()
                                                    .frame(width: 12, height: 12)
                                                    .foregroundStyle(Color.theme.accent)
                                                    .onTapGesture {
                                                        parentId = com.id
                                                        parentAuthorName = com.comment.authorName
                                                        highlightedCommentId = nil
                                                        isCommentTextFieldFocused = true
                                                        highlightedCommentId = com.id
                                                    }
                                                    .padding(.trailing, 8)
                                                Image(systemName: "flag")
                                                    .resizable()
                                                    .frame(width: 12, height: 12)
                                                    .foregroundStyle(Color.theme.accent)
                                                    .onTapGesture { }
                                                    .padding(.trailing, 8)
                                                if com.comment.authorId == profileViewModel.userId {
                                                    Image("ellipses")
                                                        .resizable()
                                                        .frame(width: 12, height: 12)
                                                        .foregroundColor(Color.theme.accent)
                                                        .onTapGesture {
                                                            selectedItemForOptions = GenericItem.comment(com.comment)
                                                            showOptionsSheet = true
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
                                            .onTapGesture {
                                                if postViewModel.upvotedComms.contains(com.id) { postViewModel.removeComUpvote(comId: com.id) }
                                                else { postViewModel.upvoteCom(comId: com.id) }
                                            }
                                            .padding(.bottom, 8)
                                        Text("\(com.comment.upvotes)")
                                            .font(.caption)
                                    }
                                    .padding(.top, 8)
                                }
                                .padding(12)
                                if com.comment.hasChildren && com.isExpanded == false && com.comment.parentCommentId == "" {
                                    HStack {
                                        Rectangle()
                                            .fill(Color.theme.gray)
                                            .frame(width: 20, height: 0.5)
                                        Text("View Replies")
                                            .font(.caption)
                                            .foregroundStyle(Color.theme.gray)
                                        Rectangle()
                                            .fill(Color.theme.gray)
                                            .frame(width: 20, height: 0.5)
                                    }
                                    .onTapGesture {
                                        Task { try await postViewModel.catchChildren(viewCom: com) }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(8)
                            .glassEffect(in: .rect(cornerRadius: 30))
                            .glassEffectUnion(id: "thread-\(postViewModel.findGrandparent(comment: com))", namespace: commentBubbles)
                            .transaction { $0.animation = nil }
                            .compositingGroup()
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
                            .padding(.top, topPadding)
                            .id("scrollId-\(com.id)")
                        } // foreach
                    }// Glasseffect
                } // else
            } // else
        } // vstack
    } // sect
    
    var commentBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Larger profile pic inline with the input
                VStack {
                    Spacer()
                    ProfilePic(address: chosenProfileImageAddress, size: 44)
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
                                    parentId = nil
                                    highlightedCommentId = nil
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
                    Image(systemName: "arrow.up")
                        .foregroundStyle(Color.theme.darkBlue)
                        .font(.title3)
                        .fontWeight(postViewModel.userUpvoted ? .bold : .regular)
                        .onTapGesture {
                            if !(postViewModel.userUpvoted || postViewModel.userDownvoted){
                                // check to see if works
                                Task {
                                    try await postViewModel.upvote(post: post)
                                    homeViewModel.upvotePost(post: post)
                                }
                            }
                            else if postViewModel.userUpvoted {
                                Task {
                                    try await postViewModel.removeUpvote(post: post)
                                    homeViewModel.removeUpvote(post: post)
                                }
                            }
                        }
                }
                HStack {
                    Text("\(post.downvotes)")
                        .font(.subheadline)
                    Image(systemName: "arrow.down")
                        .foregroundStyle(Color.theme.brightRed)
                        .font(.title3)
                        .fontWeight(postViewModel.userDownvoted ? .bold : .regular)
                        .onTapGesture {
                            if !(postViewModel.userUpvoted || postViewModel.userDownvoted){
                                Task {
                                    try await postViewModel.downvote(post: post)
                                    homeViewModel.downvotePost(post: post)
                                }
                            }
                            else if postViewModel.userDownvoted {
                                Task {
                                    try await postViewModel.removeDownvote(post: post)
                                    homeViewModel.removeDownvote(post: post)
                                }
                            }
                        }
                }
            }// hstack
            InlineExpandableText(text: post.text, limit: 200, font: .body)
                .padding(.top, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .padding()
        .background(Material.thin.opacity(0.3))
        .cornerRadius(30)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
    
    func submitComment() {
        if commentText != "" {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCommentTextFieldFocused = false
                UIApplication.shared.endEditing()
                parentAuthorName = nil
            }
            Task {
                try await postViewModel.uploadComment(message: commentText, parentId: parentId)
                try await postViewModel.fetchComments()
                commentText = ""
            }
            
        }
    }
}
