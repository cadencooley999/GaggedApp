//
//  CommentModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//
import FirebaseFirestore

struct CommentModel: Identifiable {
    let id: String
    // Post or Event id
    let postId: String
    let postName: String
    let message: String
    let authorId: String
    let authorName: String
    var authorProfPic: String
    let createdAt: Timestamp
    var upvotes: Int
    let parentCommentId: String
    var hasChildren: Bool
    let isOnEvent: Bool
}   

struct viewCommentModel: Identifiable {
    var comment: CommentModel
    var isExpanded: Bool
    let id: String
    var isGrandchild: Bool
    var threadId: String
}

struct CommentWithExpanded {
    var comment: CommentModel
    var isExpanded: Bool
}
