//
//  OptionsSheet.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/9/25.
//

import SwiftUI

struct OptionsSheet: View {
    
    @AppStorage("userId") var userId = ""
    
    var parentPostId: String?
    
    @Binding var selectedItemForOptions: GenericItem?
    @Binding var showOptionsSheet: Bool
    @Binding var showPostView: Bool
    
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var pollsViewModel: PollsViewModel
//    @EnvironmentObject var eventViewModel: EventViewModel
    
    @State var isSaved: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            VStack {
                if case .comment(_) = selectedItemForOptions {
                    EmptyView()
                }
                else {
                    HStack(spacing: 12) {
                        // Share button
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundStyle(Color.theme.accent)
                            Text("Share")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.theme.accent)
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
                        .onTapGesture {
                            // TODO: Implement share action
                        }

                        // Save button
                        VStack(spacing: 8) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundStyle(Color.theme.accent)
                            Text(isSaved ? "Saved" : "Save")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.theme.accent)
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
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
            .padding()
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
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "flag")
                            .foregroundStyle(Color.theme.brightRed)
                        Text("Report")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.theme.brightRed)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
                }
            }

            if selectedItemForOptions?.authorId == userId {
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.theme.brightRed)
                        Text("Delete")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.theme.brightRed)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
                    .onTapGesture {
                        Task {
                            if let selected = selectedItemForOptions {
                                switch selected {
                                case .post(let post):
                                    try await postViewModel.deletePost(postId: post.id)
                                    showOptionsSheet = false
                                    showPostView = false
                                    try await profileViewModel.getMoreUserPosts()
                                case .poll(let poll):
                                    try await pollsViewModel.deletePoll(pollId: poll.id)
                                    showOptionsSheet = false
                                    try await profileViewModel.getMoreUserPolls()
                                case .comment(let comment):
                                    if let postId = parentPostId {
                                        try await postViewModel.deleteComment(commentId: comment.id, postId: postId)
                                        try await postViewModel.fetchComments()
                                        showOptionsSheet = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
