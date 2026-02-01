//
//  CommentsManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

enum CommentsManagerError: Error { case invalidId, invalidUserId, invalidPostId, documentNotFound }

class CommentsManager {
    
    static let shared = CommentsManager()
    
    private var commentCollection: CollectionReference {
        Firestore.firestore().collection("Comments")
    }
    
    func uploadComment(comment: CommentModel) async throws {
        guard !comment.id.isEmpty else { throw CommentsManagerError.invalidId }
        guard !comment.postId.isEmpty else { throw CommentsManagerError.invalidPostId }
        try await commentCollection.document("\(comment.id)").setData([
            "id" : comment.id,
            "postId" : comment.postId,
            "postName" : comment.postName,
            "message": comment.message,
            "authorId" : comment.authorId,
            "authorName" : comment.authorName,
            "authorProfPic" : comment.authorProfPic,
            "createdAt" : comment.createdAt,
            "upvotes" : comment.upvotes,
            "parentCommentId" : comment.parentCommentId ?? "",
            "hasChildren" : comment.hasChildren,
            "isOnEvent" : comment.isOnEvent
        ])
    }
    
    func upvoteComment(commentId: String) async throws {
        guard !commentId.isEmpty else { throw CommentsManagerError.invalidId }
        let ref = commentCollection.document(commentId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw CommentsManagerError.documentNotFound }
        try await ref.updateData(["upvotes" : FieldValue.increment(Int64(1))])
    }
    
    func removeCommentUpvote(id: String) async throws {
        guard !id.isEmpty else { throw CommentsManagerError.invalidId }
        let ref = commentCollection.document(id)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw CommentsManagerError.documentNotFound }
        try await ref.updateData(["upvotes" : FieldValue.increment(Int64(-1))])
    }
    
    func getUserComments(userId: String) async throws -> [CommentModel] {
        guard !userId.isEmpty else { return [] }
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("authorId", isEqualTo: userId).order(by: "createdAt").limit(to: 20)
        let newDocs = try await query.getDocuments()
   
        for i in newDocs.documents {
              let comment = mapItem(item: i)
              comments.append(comment)
          }
        
        
        return comments
    }
    
    func deleteComment(commentId: String) async throws {
        guard !commentId.isEmpty else { throw CommentsManagerError.invalidId }
        let ref = commentCollection.document(commentId)
        let snap = try await ref.getDocument()
        guard snap.exists else { return }
        try await ref.delete()
    }
    
    func getComments(postId: String) async throws -> [CommentModel] {
        guard !postId.isEmpty else { return [] }
        
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("postId", isEqualTo: postId).whereField("parentCommentId", isEqualTo: "").limit(to: 20)
        let newDocs = try await query.getDocuments()
                                                
        for i in newDocs.documents {
              let comment = mapItem(item: i)
              comments.append(comment)
          }
                
        return comments
    }
    
    func updateToParent(commentId: String) async throws {
        guard !commentId.isEmpty else { throw CommentsManagerError.invalidId }
        let ref = commentCollection.document(commentId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw CommentsManagerError.documentNotFound }
        try await ref.updateData(["hasChildren" : true])
    }
    
    func getChildComments(postId: String, commentId: String) async throws -> [CommentModel] {
        guard !postId.isEmpty, !commentId.isEmpty else { return [] }
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("postId", isEqualTo: postId).whereField("parentCommentId", isEqualTo: commentId).limit(to: 100)
        let newDocs = try await query.getDocuments()
        
        print("NEW DOCS:", newDocs)
                                        
        for i in newDocs.documents {
              let comment = mapItem(item: i)
              comments.append(comment)
          }
        
        return comments
    }
    
    private func mapItem(item: QueryDocumentSnapshot) -> CommentModel {
        
        let message = item["message"] as? String ?? "No Message"
        let authorId = item["authorId"] as? String ?? "Anonymous"
        let authorName = item["authorName"] as? String ?? "Anonymous"
        let authorProfPic = item["authorProfPic"] as? String ?? ""
        let postId = item["postId"] as? String ?? "No Post Id"
        let postName = item["postName"] as? String ?? "Unnamed Post"
        let createdAt = item["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let upvotes = item["upvotes"] as? Int ?? 0
        let parentCommentId = item["parentCommentId"] as? String ?? ""
        let hasChildren = item["hasChildren"] as? Bool ?? false
        let isOnEvent = item["isOnEvent"] as? Bool ?? false
        
        return CommentModel(
            id: item.documentID,
            postId: postId,
            postName: postName,
            message: message,
            authorId: authorId,
            authorName: authorName,
            authorProfPic: authorProfPic,
            createdAt: createdAt,
            upvotes: upvotes,
            parentCommentId: parentCommentId,
            hasChildren: hasChildren,
            isOnEvent: isOnEvent
        )
    }

}
