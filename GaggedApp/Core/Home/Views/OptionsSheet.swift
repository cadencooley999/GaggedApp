//
//  OptionsSheet.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/9/25.
//

import SwiftUI

struct OptionsSheet: View {
    
    @AppStorage("userId") var userId = ""
    
    @Binding var selectedItemForOptions: GenericItem?
    @Binding var showOptionsSheet: Bool
    @Binding var showPostView: Bool
    @Binding var hideTabBar: Bool
    
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    
    @State var isSaved: Bool = false
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            VStack {
                HStack {
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                            .foregroundStyle(Color.theme.accent)
                        Text("Share")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.theme.lightGray.opacity(0.5).cornerRadius(15))
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.title)
                            .foregroundStyle(Color.theme.accent)
                        Text("Save")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.theme.lightGray.opacity(0.5).cornerRadius(15))
                    .onTapGesture {
                        print(isSaved)
                        if !isSaved {
                            if let selected = selectedItemForOptions {
                                switch selected {
                                case .post(let post):
                                    postViewModel.savePost(postId: post.id)
                                case .event(let event):
                                    eventViewModel.saveEvent(eventId: event.id)
                                case .comment(let comment):
                                    break
                                }
                                isSaved = true
                            }
                        }
                        else {
                            if let selected = selectedItemForOptions {                            isSaved = false
                                switch selected {
                                case .post(let post):
                                    postViewModel.unSavePost(postId: post.id)
                                case .event(let event):
                                    eventViewModel.unSaveEvent(eventId: event.id)
                                case .comment(let comment):
                                    break
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
                    case .event(let event):
                        Task {
                            isSaved = await eventViewModel.isSaved(eventId: event.id)
                        }
                    case .comment(let comment):
                        break
                    }
                }

            }
        }
    }
    
    var actionsList: some View {
        VStack(alignment: .leading, spacing: 0){
            HStack {
                ZStack {
                    Color.clear
                    Image(systemName: "flag")
                        .foregroundStyle(Color.theme.brightRed)
                }
                .frame(width: 20)
                Text("Report")
                    .font(.body)
                    .foregroundColor(Color.theme.brightRed)
                Spacer()
            }
            .padding()
            .frame(height: 50)
            if selectedItemForOptions?.authorId == userId {
                Divider()
                HStack {
                    ZStack {
                        Color.clear
                        Image(systemName: "trash")
                            .foregroundStyle(Color.theme.brightRed)
                    }
                    .frame(width: 20)
                    Text("Delete")
                        .font(.body)
                        .foregroundColor(Color.theme.brightRed)
                        .onTapGesture {
                            print("tapped")
                            Task {
                                if let selected = selectedItemForOptions {
                                    print(selected.id, "SELECTED ID")
                                    switch selected {
                                    case .post(let post):
                                        try await postViewModel.deletePost(postId: post.id)
                                        try await profileViewModel.getMoreUserPosts()
                                        showOptionsSheet = false
                                        showPostView = false
                                        hideTabBar = false
                                    case .event(let event):
                                        try await eventViewModel.deleteEvent(eventId: event.id)
                                        try await profileViewModel.getMoreUserEvents()
                                        showOptionsSheet = false
                                        showPostView = false
                                        hideTabBar = false
                                    case .comment(let comment):
                                        try await postViewModel.deleteComment(commentId: comment.id)
                                        try await postViewModel.fetchComments()
                                        showOptionsSheet = false
                                    }
                                }

                            }
                        }
                    Spacer()
                }
                .padding()
                .frame(height: 50)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.theme.lightGray.opacity(0.5).cornerRadius(15))
    }
}
