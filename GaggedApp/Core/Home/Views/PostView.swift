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

    
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @FocusState var isCommentTextFieldFocused: Bool
    
    @Binding var showPostView: Bool
    @Binding var showSearchView: Bool
    @Binding var hideTabBar: Bool
    
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

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            
            if let post = postViewModel.post {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            postImage(url: post.imageUrl, maxHeight: 450)
                                .onTapGesture {
                                    UIApplication.shared.endEditing()
                                }
                            
                            postInfo(for: post)
                                .padding()
                                .id("postTop")
                                .padding(.bottom, 4)
                            
                            Divider()

                            commentSection
                                .id("commentSectionBottom")
                                .padding(.bottom, 32)

                        }
                        .offset(y: shiftScroll ? (highlightedCommentId != nil ? -300 : -250) : 0)
                        .padding(.vertical, 55)
                        .onChange(of: isCommentTextFieldFocused) { newValue in
                            if newValue {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    shiftScroll = true
                                }
                            }
                            else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    shiftScroll = false
                                }
                            }
                        }
                    }
                    .refreshable {
                        Task {
                            try await postViewModel.fetchComments()
                        }
                    }
                    .onScrollPhaseChange { oldPhase, newPhase in
                        if newPhase == .interacting {
                            UIApplication.shared.endEditing()
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
                header
                    .background(Color.theme.background)
                Divider()
                Spacer()
                commentBar
                    .background(Color.theme.background)
                    .focused($isCommentTextFieldFocused)
            }
            
            if showProfilePopup {
                if let author = userForDisplay {
                    ProfilePopup(user: author, showProfilePopup: $showProfilePopup, thingHeldId: $thingHeldId)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showProfilePopup)
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView)
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
                    .frame(width: 50, alignment: .leading)
                    .frame(maxHeight: .infinity)
                    .background(Color.theme.background)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPostView = false
                            hideTabBar = false
                        }
                        postViewModel.comments = []
                    }
                VStack {
                    Text(postViewModel.post?.name ?? "Name")
                        .font(.title2)
                    HStack {
                        ForEach(postViewModel.postCities) { city in
                            Text(city.city + ", " + city.state_id.uppercased())
                                .italic(true)
                                .font(.callout)
                                .lineLimit(1)
                            if postViewModel.postCities.count > 1 {
                                if city == postViewModel.postCities.first! {
                                    Text("&")
                                        .italic(true)
                                        .font(.callout)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    Image("ellipses")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            if let post = postViewModel.post {
                                selectedItemForOptions = GenericItem.post(post)
                                showOptionsSheet = true
                            }
                        }
                }
                .frame(maxWidth: 50, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .frame(height: 55)
    }
    
    var commentSection: some View {
            VStack(spacing: 0) {
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
                        ForEach(postViewModel.comments) { com in
                            HStack(alignment: .top) {
                                HStack(alignment: .top){
                                    ProfilePic(address: com.uiComment.author.imageAddress, size: 25)
                                        .scaleEffect(thingHeldId == com.uiComment.id ? 0.9 : 1)
                                        .onLongPressGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showProfilePopup(user: com.uiComment.author)
                                                thingHeldId = com.uiComment.id
                                            }
                                        }
                                    VStack(alignment: .leading){
                                        HStack {
                                            Text(com.uiComment.author.username)
                                                .font(.caption)
                                                .scaleEffect(thingHeldId == com.uiComment.id ? 0.9 : 1)
                                                .onLongPressGesture {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showProfilePopup(user: com.uiComment.author)
                                                        thingHeldId = com.uiComment.id
                                                    }
                                                }
                                            Text(postViewModel.timeAgoString(from: com.uiComment.comment.createdAt))
                                                .font(.caption)
                                                .foregroundStyle(Color.theme.gray)
                                        }
                                        .padding(.bottom, 4)
                                        (Text(com.isGrandchild
                                              ? "@\(postViewModel.getAuthorName(id: com.uiComment.comment.parentCommentId ?? "") ?? "") "
                                              : "").foregroundStyle(Color.blue).font(.subheadline))
                                        + Text(com.uiComment.comment.message)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.theme.accent)
                                        HStack {
                                            Image(systemName: "message")
                                                .resizable()
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(Color.theme.accent)
                                                .onTapGesture {
                                                    parentId = com.uiComment.id
                                                    parentAuthorName = com.uiComment.author.username
                                                    highlightedCommentId = com.uiComment.id
                                                    isCommentTextFieldFocused = true
                                                }
                                                .padding(.trailing, 8)
                                            Image(systemName: "flag")
                                                .resizable()
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(Color.theme.accent)
                                                .onTapGesture {
                                                    
                                                }
                                                .padding(.trailing, 8)
                                            if com.uiComment.author.id == profileViewModel.userId {
                                                Image("ellipses")
                                                    .resizable()
                                                    .frame(width: 12, height: 12)
                                                    .foregroundColor(Color.theme.accent)
                                                    .onTapGesture {
                                                        selectedItemForOptions = GenericItem.comment(com.uiComment.comment)
                                                        showOptionsSheet = true
                                                    }
                                                
                                            }
                                            Spacer()
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(.leading, com.indentLayer > 0 ? 16 : 0)
                                Spacer()
                                VStack {
                                    Image(systemName: "arrow.up")
                                        .foregroundStyle(postViewModel.upvotedComms.contains(com.id) ? Color.theme.darkBlue : .gray)
                                        .onTapGesture {
                                            if postViewModel.upvotedComms.contains(com.id) {
                                                postViewModel.removeComUpvote(comId: com.id)
                                            } else {
                                                postViewModel.upvoteCom(comId: com.id)
                                            }
                                        }
                                        .padding(.bottom, 8)
                                    Text("\(com.uiComment.comment.upvotes)")
                                        .font(.caption)
                                }
                                .padding(.top, 8)
                            }
                            .padding(12)
                            .background(content: {
                                Color.theme.gray.opacity(com.id == highlightedCommentId ? 0.4 : 0.0)
                            })
                            if com.uiComment.comment.hasChildren && com.isExpanded == false && com.indentLayer < 1 {
                                Text("--- View Replies ---")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.gray)
                                    .onTapGesture {
                                        Task {
                                            try await postViewModel.catchChildren(viewCom: com)
                                            print("child fetched")
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
//                            else if com.comment.hasChildren && com.isExpanded == true {
//                                Text("--- Hide Replies ---")
//                                    .font(.caption)
//                                    .foregroundStyle(Color.theme.gray)
//                                    .onTapGesture {
//                                        postViewModel.collapseComments(viewComment: com)
//                                    }
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                            }
                        } // foreach
                    } // else
                } // else
            } // vstack
    } // sect
    
    var commentBar: some View {
        VStack(spacing: 0){
            Divider()
            HStack(alignment: .bottom){
                ProfilePic(address: chosenProfileImageAddress, size: 25)
                VStack {
                    if parentAuthorName != nil {
                        HStack {
                            Text("Replying to @\(parentAuthorName!)")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            Image(systemName: "xmark")
                                .font(.headline)
                                .onTapGesture {
                                    parentId = nil
                                    parentAuthorName = nil
                                    highlightedCommentId = nil
                                    UIApplication.shared.endEditing()
                                }
                        }
                    }
                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .focused($isCommentTextFieldFocused)
                        .lineLimit(4)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color.theme.lightGray.opacity(0.5))
                        )
                }
                Image(systemName: "paperplane")
                    .resizable()
                    .foregroundStyle(Color.theme.lightBlue)
                    .onTapGesture {
                        submitComment()
                        highlightedCommentId = nil
                    }
                    .frame(width: 20, height: 20)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func postInfo(for post: PostModel) -> some View {
        VStack {
            HStack {
                HStack {
                    HStack {
                        ProfilePic(address: postViewModel.postAuthor?.imageAddress ?? "", size: 25)
                        Text("\(postViewModel.postAuthor?.username ?? "")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .background(Color.theme.background)
                    .scaleEffect(thingHeldId == post.id ? 0.9 : 1)
                    .onLongPressGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showProfilePopup(user: postViewModel.postAuthor ?? nil)
                            thingHeldId = post.id
                        }
                    }
                    Text("•")
                        .font(.caption)
                    Text(postViewModel.timeAgoString(from: post.createdAt))
                        .font(.subheadline)
                }
                Spacer()
                HStack {
                    Text("\(post.upvotes)")
                        .font(.headline)
                    Image(systemName: "arrow.up")
                        .foregroundStyle(Color.theme.darkBlue)
                        .font(.title3)
                        .fontWeight(postViewModel.userUpvoted ? .bold : .regular)
                        .onTapGesture {
                            if !(postViewModel.userUpvoted || postViewModel.userDownvoted){
                                postViewModel.upvote(post: post)
                                homeViewModel.upvotePost(post: post)
                            }
                            else if postViewModel.userUpvoted {
                                postViewModel.removeUpvote(post: post)
                                homeViewModel.removeUpvote(post: post)
                            }
                        }
                }
                HStack {
                    Text("\(post.downvotes)")
                        .font(.headline)
                    Image(systemName: "arrow.down")
                        .foregroundStyle(Color.theme.brightRed)
                        .font(.title3)
                        .fontWeight(postViewModel.userDownvoted ? .bold : .regular)
                        .onTapGesture {
                            if !(postViewModel.userUpvoted || postViewModel.userDownvoted){
                                postViewModel.downvote(post: post)
                                homeViewModel.downvotePost(post: post)
                            }
                            else if postViewModel.userDownvoted {
                                postViewModel.removeDownvote(post: post)
                                homeViewModel.removeDownvote(post: post)
                            }
                        }
                }
            }// hstack
            InlineExpandableText(text: post.text, limit: 200)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

        }
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
    
    func showProfilePopup(user: UserModel?) {
        userForDisplay = user
        showProfilePopup = true
    }
}

struct ProfilePopup: View {
    
    let user: UserModel
    @Binding var showProfilePopup: Bool
    @Binding var thingHeldId: String
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                    HStack {
                        ProfilePic(address: user.imageAddress, size: 70)
                        VStack {
                            Text(user.username)
                                .font(.headline)
                            HStack {
                                VStack {
                                    Text("\(user.garma)")
                                        .font(.body)
                                    Text("gags")
                                        .font(.caption)
                                }
                                VStack {
                                    Text("3")
                                        .font(.body)
                                    Text("posts")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Rectangle().fill(Color.theme.background).cornerRadius(20).shadow(radius: 10))
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial.opacity(0.5))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showProfilePopup = false
                thingHeldId = ""
            }
        }
    }
}
