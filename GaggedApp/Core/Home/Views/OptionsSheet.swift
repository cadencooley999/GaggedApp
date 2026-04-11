//
//  OptionsSheet.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/9/25.
//

import SwiftUI

struct OptionsSheet: View {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("isAdmin") var isAdmin = false
    
    var parentPostId: String?
    
    @Binding var selectedItemForOptions: GenericItem?
    @Binding var showOptionsSheet: Bool
    @Binding var showPostView: Bool
    @Binding var showPollView: Bool
    
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var inspectionViewModel: InspectionViewModel
    @EnvironmentObject var leaderViewModel: LeaderViewModel
//    @EnvironmentObject var eventViewModel: EventViewModel
    
    @Binding var showReportSheet: Bool
    @Binding var preReportInfo: preReportModel?
    
    let screenType: ScreenType
    
    @State var isSaved: Bool = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack {
                if case .comment(_) = selectedItemForOptions {
                    EmptyView()
                }
                else {
                    HStack(spacing: 12) {
                        // Share button
                        ShareLink(item: generateDeepLink()) {
                            VStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.theme.accent)
                                Text("Share")
                                    .font(.callout)
                                    .foregroundStyle(Color.theme.accent)
                            }
                            .padding(.vertical, 18)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .contentShape(Rectangle())
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                        }

                        // Save button
                        VStack(spacing: 10) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.theme.accent)
                            Text(isSaved ? "Saved" : "Save")
                                .font(.callout)
                                .foregroundStyle(Color.theme.accent)
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                        .onTapGesture {
                            if !isSaved {
                                if let selected = selectedItemForOptions {
                                    switch selected {
                                    case .post(let post):
                                        postViewModel.savePost(postId: post.id)
                                    case .poll(let poll):
                                        CoreDataManager.shared.savePoll(pollId: poll.id)
                                    case .comment:
                                        break
                                    }
                                    isSaved = true
                                }
                            } else {
                                if let selected = selectedItemForOptions {
                                    isSaved = false
                                    switch selected {
                                    case .post(let post):
                                        postViewModel.unSavePost(postId: post.id)
                                    case .poll(let poll):
                                        CoreDataManager.shared.deleteSaved(id: poll.id)
                                    case .comment:
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                actionsList
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.top, 8)
            .task {
                if let selected = selectedItemForOptions {
                    switch selected {
                    case .post(let post):
                        Task {
                            isSaved = await postViewModel.isSaved(postId: post.id)
                        }
                    case .poll(let poll):
                        Task {
                            isSaved = await pollsViewModel.isSaved(pollId: poll.id)
                        }
                    case .comment(let comment):
                        break
                    }
                }

            }
        }
    }
    
    var actionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if case .comment(_) = selectedItemForOptions {
                EmptyView()
            } else {
                if selectedItemForOptions?.authorId != userId {
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.square")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.theme.brightRed)
                            Text("Block User")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Color.theme.brightRed)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 56)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                    }
                    .onTapGesture {
                        showOptionsSheet = false
                        if let authorId = selectedItemForOptions?.authorId {
                            if authorId != userId {
                                print("Blocking author ", authorId)
                                Task {
                                    try await BlockingManager.shared.blockUser(userId: userId, targetId: authorId)
                                    feedStore.blocked.insert(authorId)

                                    // Reset all feeds/state that can cache content
                                    homeViewModel.reset()
                                    pollsViewModel.reset()
                                    searchViewModel.resetGlobalPosts()
                                    searchViewModel.resetGlobalPolls()
                                    profileViewModel.resetSaved()
                                    postViewModel.resetRootComments()
                                    leaderViewModel.reset()

                                    // Dismiss currently presented views for the selected item
                                    switch selectedItemForOptions {
                                    case .post:
                                        showPostView = false
                                    case .comment:
                                        // If we're on a post detail, refresh root comments after blocking
                                        try await postViewModel.loadInitialRootComments(blockedIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .poll:
                                        showPollView = false
                                    case .none:
                                        break
                                    }

                                    // Reload only the feed that corresponds to the current screen
                                    switch screenType {
                                    case .searchFeed:
                                        try await searchViewModel.loadInitialGlobalPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                        try await searchViewModel.loadInitialGlobalPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .pollsFeed:
                                        try await pollsViewModel.getInitialPolls(cityIds: LocationManager.shared.citiesInRange)
                                    case .profileFeed:
                                        // Reload both posts and polls for profile to reflect block
                                        await profileViewModel.loadInitialUserPosts(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                        await profileViewModel.loadInitialUserPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .savedFeed:
                                        try await profileViewModel.loadSavedIfNeeded(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .inspectionFeed:
                                        // If there is an inspection feed, refresh it to reflect block
                                        await inspectionViewModel.loadInitialReportedPolls()
                                    case .homeFeed:
                                        await homeViewModel.loadInitialPostFeed(cityIds: LocationManager.shared.citiesInRange)
                                    case .leaderBoard:
                                        try await leaderViewModel.fetchMoreLeaderboards(cities: LocationManager.shared.citiesInRange, blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    @unknown default:
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "flag")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.theme.brightRed)
                        Text("Report")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.theme.brightRed)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                }
                .onTapGesture {
                    showOptionsSheet = false
                    showReportSheet = true
                }
            }

            if (selectedItemForOptions?.authorId == userId) || isAdmin {
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.theme.brightRed)
                        Text("Delete")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.theme.brightRed)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                    .onTapGesture {
                        Task {
                            if let selected = selectedItemForOptions {
                                switch selected {
                                case .post(let post):
                                    showOptionsSheet = false
                                    try await postViewModel.deletePost(postId: post.id)
                                    homeViewModel.removePostFromFeed(postId: post.id)
                                    showPostView = false
                                    await profileViewModel.loadInitialUserPosts()
                                case .poll(let poll):
                                    showOptionsSheet = false
                                    showPollView = false
                                    try await pollsViewModel.deletePoll(pollId: poll.id)
                                    switch screenType {
                                    case .searchFeed:
                                        try await searchViewModel.loadInitialGlobalPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .pollsFeed:
                                        try await pollsViewModel.getInitialPolls(cityIds: LocationManager.shared.citiesInRange)
                                    case .profileFeed:
                                        await profileViewModel.loadInitialUserPolls(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .savedFeed:
                                        try await profileViewModel.refreshSaved(blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                                    case .inspectionFeed:
                                        await inspectionViewModel.loadInitialReportedPolls()
                                    case .homeFeed:
                                        // No polls on home feed; nothing to reload
                                        break
                                    case .leaderBoard:
                                        // Leaderboard unaffected by poll deletion
                                        break
                                    @unknown default:
                                        break
                                    }
                                
                                case .comment(let comment):
                                    if let postId = parentPostId {
                                        showOptionsSheet = false
                                        try await postViewModel.deleteComment(commentId: comment.id, postId: postId, ancestorId: comment.ancestorId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func generateDeepLink() -> String {
        var urlString = "https://gaggedapp.web.app/"
        if let selected = selectedItemForOptions {
            switch selected {
                
            case .post(_):
                urlString.append("post/\(selected.id)")
            case .comment(_):
                urlString.append("")
            case .poll(_):
                urlString.append("poll/\(selected.id)")
            }
        }
        return urlString
    }
}
