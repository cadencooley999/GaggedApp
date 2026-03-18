//
//  CommentModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//
import FirebaseFirestore

struct CommentModel: Identifiable {
    let id: String
    let postId: String
    let postName: String
    let message: String
    let authorId: String
    let authorName: String
    var authorProfPic: String
    let createdAt: Timestamp
    var upvotes: Int
    let parentCommentId: String
    let parentAuthorId: String
    let parentAuthorName: String
    let ancestorId: String
    var hasChildren: Bool
    let isOnEvent: Bool
    let isGrand: Bool
}

struct viewCommentModel: Identifiable {
    var comment: CommentModel
    let id: String
    var commentThreadState: CommentThreadState?
}

struct CommentThreadState {
    var children: [viewCommentModel] = []
    var cursor: CommentsCursor? = nil
    var hasMore: Bool = true
    var isLoading: Bool = false
    var isExpanded: Bool = false
}
