//
//  InspectionView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/27/26.
//
import SwiftUI
import Foundation

enum InspectionFilter: String, CaseIterable {
    case posts = "Posts"
    case polls = "Polls"
    case comments = "Comments"
}

struct InspectionView: View {
    
    @EnvironmentObject var vm: InspectionViewModel
    @EnvironmentObject var windowSize: WindowSize
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var postViewModel: PostViewModel

    @Binding var showInspectionView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var showPollView: Bool
    @Binding var showReportView: Bool
    @Binding var preReportInfo: preReportModel?
    
    @State private var selectedFilter: InspectionFilter = .posts
    @Namespace private var segmentedSwitch
    
    var body: some View {
        ZStack {
            // Background matching Home/Settings
            Background()
                .ignoresSafeArea()
            
            // Content under the segmented pill
            VStack {
                content(currentFilter: selectedFilter)
            }
            
            // Header overlay with apple blur + gradient mask like Home/Settings
            VStack {
                ZStack(alignment: .top) {
                    VStack {
                        BackgroundHelper.shared.appleHeaderBlur.frame(height: 92)
                        Spacer()
                    }
                    
                    VStack {
                        header
                            .frame(height: 55)
                            .zIndex(1)
                        Spacer()
                    }
                }
                Spacer()
            }
            
            // Segmented controller floating below header
            VStack {
                segmentedController
                    .padding(.top, 120)
                    .frame(height: 55)
                Spacer()
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            // xmark like ReportSheet header
            Image(systemName: "xmark")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showInspectionView = false
                    }
                }
            
            Spacer()
            
            VStack {
                Text("Review Reported Content")
                    .font(.headline)
                    .foregroundStyle(Color.theme.accent)
                    .padding(.bottom, 4)
                
                Text("Pull to refresh")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.gray)
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Image(systemName: "xmark")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .opacity(0)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Segmented Controller (3 options like Search)
    private var segmentedController: some View {
        let selected = selectedFilter
        
        return HStack(spacing: 6) {
            ForEach(InspectionFilter.allCases, id: \.self) { filter in
                segmentButton(
                    title: filter.rawValue,
                    isSelected: selected == filter,
                    namespace: segmentedSwitch
                ) {
                    guard selected != filter else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedFilter = filter
                    }
                }
            }
        }
        .padding(2)
        .glassEffect()
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func segmentButton(
        title: String,
        isSelected: Bool,
        namespace: Namespace.ID,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            if isSelected {
                Capsule()
                    .fill(Color.theme.lightBlue.opacity(0.2))
                    .matchedGeometryEffect(id: "SEGMENT_PILL", in: namespace)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
            }
            
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(Color.theme.darkBlue)
                .padding(.vertical, 6)
                .padding(.horizontal)
        }
        .contentShape(Capsule())
        .onTapGesture(perform: action)
        .frame(width: 110)
    }

    private func flagsRow(reasons: [String]) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "flag.fill")
                .font(.caption)
                .foregroundStyle(Color.theme.darkRed)
            if reasons.isEmpty {
                Text("No flags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(reasons, id: \.self) { reason in
                    Text(reason)
                        .font(.caption.bold())
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.theme.lightGray.opacity(0.2))
                        )
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func actionRow(approveAction: @escaping () -> Void, removeAction: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                approveAction()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    Text("Approve")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.green)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.green.opacity(0.12)))
            }
            Spacer()
            Button(action: {
                removeAction()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.headline)
                    Text("Remove")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.theme.darkRed)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.theme.darkRed.opacity(0.10)))
            }
        }
        .padding(.top, 4)
    }

    private func actionRowCompact(approveAction: @escaping () -> Void, removeAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                approveAction()
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.green)
                    .padding(6)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
            }
            Spacer(minLength: 8)
            Button(action: {
                removeAction()
            }) {
                Image(systemName: "trash.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.darkRed)
                    .padding(6)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
            }
        }
        .padding(.top, 2)
    }
    
    // MARK: - Content
    @ViewBuilder
    private func content(currentFilter: InspectionFilter) -> some View {
        switch currentFilter {
        case .posts:
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(),GridItem()]) {
                    ForEach(vm.reportedPosts, id: \.post.id) { post in
                        VStack(alignment: .leading, spacing: 10) {
                            flagsRow(reasons: post.reportReasons)

                            VStack {
                                MiniPostView(post: post.post, width: windowSize.size.width, stroked: false)
                                    .onAppear {
                                        if post.post.id == vm.reportedPosts.last?.post.id {
                                            Task {
                                                await vm.fetchMoreReportedPosts()
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        print("Little Post Tapped")
                                        selectedPost = post.post
                                        postViewModel.setPost(postSelection: post.post)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showPostView = true
                                        }
                                        Task {
                                            postViewModel.commentsIsLoading = true
                                            print("home com fetch")
                                            try await postViewModel.loadInitialRootComments()
                                            postViewModel.commentsIsLoading = false
                                        }
                                    }
                            }

                            actionRowCompact(approveAction: {
                                Task {
                                    try await vm.approvePost(postId: post.post.id)
                                }
                            }, removeAction: {
                                Task {
                                    try await vm.deletePost(postId: post.post.id, authorId: post.post.authorId)
                                }
                            })
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 124)
                .padding(.bottom, 100)
                .padding(.horizontal, 8)
                .customRefreshable {
                    await vm.loadInitialReportedPosts()
                }
            }
            .background(Color.theme.background.ignoresSafeArea())
            .task {
                if vm.hasMorePosts && vm.reportedPosts.isEmpty {
                    await vm.loadInitialReportedPosts()
                }
            }
            .coordinateSpace(name: "scroll")
        case .polls:
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(vm.reportedPolls, id: \.pollwithoptions.id) { poll in
                        LazyVStack(alignment: .leading, spacing: 10) {
                            flagsRow(reasons: poll.reportReasons)
                                .padding(.top)

                            VStack {
                                PollCard(screenType: .inspectionFeed, poll: poll.pollwithoptions.poll, options: poll.pollwithoptions.options, selectedPost: $selectedPost, showPostView: $showPostView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo)
                                    .padding(.vertical, 4)
                                    .onAppear {
                                        if poll.pollwithoptions.id == vm.reportedPolls.last?.pollwithoptions.id {
                                            Task {
                                                await vm.fetchMoreReportedPolls()
                                            }
                                        }
                                    }
                            }

                            actionRow(approveAction: {
                                Task {
                                    try await vm.approvePoll(pollId: poll.pollwithoptions.poll.id)
                                }
                            }, removeAction: {
                                Task {
                                    try await vm.deletePoll(pollId: poll.pollwithoptions.id, authorId: poll.pollwithoptions.poll.authorId)
                                }
                            })
                        }
                        .padding(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 112)
                .padding(.bottom, 100)
                .customRefreshable {
                    await vm.loadInitialReportedPolls()
                }
            }
            .background(Color.theme.background.ignoresSafeArea())
            .task {
                if vm.hasMorePolls && vm.reportedPolls.isEmpty {
                    await vm.loadInitialReportedPolls()
                }
            }
            .coordinateSpace(name: "scroll")
        case .comments:
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(vm.reportedComments, id: \ReportedComment.comment.id) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 10) {
                                flagsRow(reasons: comment.reportReasons)
                                VStack(alignment: .leading, spacing: 6) {
                                    // Username
                                    Text(comment.comment.authorName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.primary)

                                    // Date
                                    Text(profileViewModel.formatFirestoreDate(comment.comment.createdAt))
                                        .font(.footnote)
                                        .foregroundStyle(Color.secondary)
                                        .fontWeight(.regular)

                                    HStack {
                                        Text(comment.comment.message)
                                            .padding(12)
                                            .background(Color.theme.lightGray.opacity(0.15))
                                            .cornerRadius(8)

                                        Spacer()

                                        HStack(spacing: 2){
                                            Text("\(comment.comment.upvotes)")
                                            Image(systemName: "arrow.up")
                                                .foregroundStyle(Color.theme.darkBlue)
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    }
                                    .padding(.leading, 8)
                                    .padding(.top, 8)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius:16, style: .continuous).fill(.ultraThinMaterial))
                                .onAppear {
                                    if comment.comment.id == vm.reportedComments.last?.comment.id {
                                        Task {
                                            await vm.fetchMoreReportedComments()
                                        }
                                    }
                                }

                                actionRow(approveAction: {
                                    Task {
                                        try await vm.approveComment(commentId: comment.comment.id)
                                    }
                                }, removeAction: {
                                    Task {
                                        try await vm.deleteComment(commentId: comment.comment.id, authorId: comment.comment.authorId)
                                    }
                                })
                            }

                            Spacer()

                            Button {
                                Task {
                                    let post = try await postViewModel.fetchPost(postId: comment.comment.postId)
                                    selectedPost = post
                                    postViewModel.setPost(postSelection: post)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPostView = true
                                    }
                                    postViewModel.commentsIsLoading = true
                                    try await postViewModel.loadInitialRootComments()
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 124)
                .padding(.bottom, 100)
                .customRefreshable {
                    await vm.loadInitialReportedComments()
                }
            }
            .background(Color.theme.background.ignoresSafeArea())
            .task {
                if vm.hasMoreComments && vm.reportedComments.isEmpty {
                    await vm.loadInitialReportedComments()
                }
            }
            .coordinateSpace(name: "scroll")
        }
    }
}

