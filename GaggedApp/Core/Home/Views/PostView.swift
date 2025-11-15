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
    @AppStorage("profImageUrl") var profImageUrl = ""
    
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @FocusState var isCommentTextFieldFocused: Bool
    
    @Binding var showPostView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showSearchView: Bool
    
    @State var commentText: String = ""
    @State var shiftScroll: Bool = false
    @State private var textEditorHeight: CGFloat = 36
    @State var parentId: String? = nil
    @State var parentAuthor: String? = nil
    @State var highlightedCommentId: String? = nil
    @State var showOptionsSheet: Bool = false
    @State var selectedItemForOptions: GenericItem? = nil
    
    let cityUtil = CityUtility.shared

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
//                            Image("Moose")
//                                .resizable()
//                                .scaledToFill()
//                                .frame(maxWidth: .infinity)
//                                .onTapGesture {
//                                    UIApplication.shared.endEditing()
//                                }
                            
//                            CachedImage(post.imageUrl) { image in
//                                image
//                                    .frame(maxWidth: .infinity)
//                                    .frame(maxHeight: 350)
//                                    .clipped()
//                                    .onTapGesture {
//                                        UIApplication.shared.endEditing()
//                                    }
//                            } placeholder: {
//                                ZStack {
//                                    ProgressView()
//                                        .scaledToFill()
//                                }
//                                .frame(height: 350)
//                            } failure: {
//                                ZStack {
//                                    ProgressView()
//                                        .scaledToFill()
//                                }
//                                .frame(height: 350)
//                            }
                            postImage(url: post.imageUrl, maxHeight: 450)
                                .onTapGesture {
                                    UIApplication.shared.endEditing()
                                }
                            
                            postInfo(for: post)
                                .padding()
                                .id("postTop")
                                .padding(.bottom, 8)
                            
                            Divider()

                            commentSection
                                .id("commentSectionBottom")
                                .padding(.bottom, 32)

                        }
                        .offset(y: shiftScroll ? -200 : 0)
                        .padding(.vertical, 56)
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
                .highPriorityGesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 80 { // left swipe
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPostView = false
                                }
                                if !showSearchView {
                                    hideTabBar = false
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
        }
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView, hideTabBar: $hideTabBar)
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
                    .frame(maxWidth: 50, alignment: .leading)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPostView = false
                        }
                        if !showSearchView {
                            hideTabBar = false
                        }
                        postViewModel.comments = []
                    }
                VStack {
                    Text(postViewModel.post?.name ?? "Name")
                        .font(.title2)
                    if let cities = postViewModel.post?.cities {
                        HStack {
                            ForEach(cities) { city in
                                Text(city.name + ", " + (cityUtil.getStateAbbreviation(for: city.state) ?? ""))
                                    .italic(true)
                                    .font(.callout)
                                    .lineLimit(1)
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
        ScrollView(showsIndicators: false) {
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
                                    profileImageClip(url: profileViewModel.profImageUrl, height: 20)
                                    VStack(alignment: .leading){
                                        HStack {
                                            Text(com.comment.authorName)
                                                .font(.subheadline)
                                            Text(postViewModel.timeAgoString(from: com.comment.createdAt))
                                                .font(.caption)
                                                .foregroundStyle(Color.theme.gray)
                                        }
                                        (Text(com.isGrandchild
                                             ? "@\(postViewModel.getAuthor(id: com.comment.parentCommentId ?? "") ?? "") "
                                              : "").foregroundStyle(Color.blue).font(.caption))
                                        + Text(com.comment.message)
                                            .font(.caption)
                                            .foregroundStyle(Color.theme.accent)
                                        HStack {
                                            Image(systemName: "message")
                                                .resizable()
                                                .frame(width: 12, height: 12)
                                                .foregroundStyle(Color.theme.accent)
                                                .onTapGesture {
                                                    parentId = com.comment.id
                                                    parentAuthor = com.comment.authorId
                                                    highlightedCommentId = com.comment.id
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
                                .padding(.leading, com.indentLayer > 0 ? 16 : 0)
                                Spacer()
                                VStack {
                                    Image(systemName: "arrow.up")
                                        .foregroundStyle(.gray)
                                        .onTapGesture {
                                            postViewModel.upvoteCom(comId: com.id)
                                            if com.comment.authorId == profileViewModel.userId {
                                                Task {
                                                    try await profileViewModel.getMoreUserComments()
                                                }
                                            }
                                        }
                                        .padding(.bottom, 8)
                                    Text("\(com.comment.upvotes)")
                                        .font(.caption)
                                }
                                .padding(.top, 8)
                            }
                            .padding(12)
                            .background(content: {
                                Color.theme.gray.opacity(com.id == highlightedCommentId ? 0.4 : 0.0)
                            })
                            if com.comment.hasChildren && com.isExpanded == false && com.indentLayer < 1 {
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
        } // scrollview
    } // sect
    
    var commentBar: some View {
        VStack(spacing: 0){
            Divider()
            HStack(alignment: .bottom){
                profileImageClip(url: profileViewModel.profImageUrl, height: 20)
                VStack {
                    if parentId != nil {
                        HStack {
                            Text("Replying to @\(parentAuthor!)")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            Image(systemName: "xmark")
                                .font(.headline)
                                .onTapGesture {
                                    parentId = nil
                                    parentAuthor = nil
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
                        if commentText != "" {
                            Task {
                                try await postViewModel.uploadComment(message: commentText, parentId: parentId)
                                commentText = ""
                                try await postViewModel.fetchComments()
                            }
                        }
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
                    Image(systemName: "person.circle")
                        .font(.headline)
                    Text("\(post.authorId)")
                        .font(.subheadline)
                        .fontWeight(.medium)
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
                        .fontWeight(.bold)
                        .onTapGesture {
                            postViewModel.upvote(post: post)
                            homeViewModel.upvotePost(post: post)
                            if post.authorId == profileViewModel.userId {
                                Task {
                                    try await profileViewModel.getMoreUserPosts()
                                }
                            }
                        }
                }
                HStack {
                    Text("\(post.downvotes)")
                        .font(.headline)
                    Image(systemName: "arrow.down")
                        .foregroundStyle(Color.theme.brightRed)
                        .fontWeight(.bold)
                        .onTapGesture {
                            postViewModel.downvote(post: post)
                            homeViewModel.downvotePost(post: post)
                            if post.authorId == userId {
                                Task {
                                    try await profileViewModel.getMoreUserPosts()
                                }
                            }
                        }
                }
            }// hstack
            InlineExpandableText(text: post.text, limit: 200)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

        }
    }
}

#Preview {
    PostView(showPostView: .constant(true), hideTabBar: .constant(false), showSearchView: .constant(false))
        .environmentObject(HomeViewModel.previewModel())
        .environmentObject(PostViewModel.previewModel())
}
