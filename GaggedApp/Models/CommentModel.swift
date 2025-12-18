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
    let createdAt: Timestamp
    var upvotes: Int
    let parentCommentId: String?
    var hasChildren: Bool
    let isOnEvent: Bool
}

struct UICommentModel: Identifiable {
    let id: String
    var comment: CommentModel
    let author: UserModel
}

struct viewCommentModel: Identifiable {
    var uiComment: UICommentModel
    var isExpanded: Bool
    let id: String
    let indentLayer: Int
    var numChildren: Int
    let isGrandchild: Bool
}
