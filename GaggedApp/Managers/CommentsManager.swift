//
//  CommentsManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class CommentsManager {
    
    static let shared = CommentsManager()
    
    private var commentCollection: CollectionReference {
        Firestore.firestore().collection("Comments")
    }
    
    func uploadComment(comment: CommentModel) async throws {
        try await commentCollection.document("\(comment.id)").setData([
            "id" : comment.id,
            "postId" : comment.postId,
            "postName" : comment.postName,
            "message": comment.message,
            "authorId" : comment.authorId,
            "createdAt" : comment.createdAt,
            "upvotes" : comment.upvotes,
            "parentCommentId" : comment.parentCommentId ?? "",
            "hasChildren" : comment.hasChildren,
            "isOnEvent" : comment.isOnEvent
        ])
    }
    
    func upvoteComment(commentId: String) async throws {
        try await commentCollection.document(commentId).updateData(["upvotes" : FieldValue.increment(Int64(1))])
    }
    
    func removeCommentUpvote(id: String) async throws {
        try await commentCollection.document(id).updateData(["upvotes" : FieldValue.increment(Int64(-1))])
    }
    
    func getUserComments(userId: String) async throws -> [CommentModel] {
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("authorId", isEqualTo: userId).order(by: "createdAt").limit(to: 20)
        let newDocs = try await query.getDocuments()
   
        for i in newDocs.documents {
              let comment = await mapItem(item: i)
              comments.append(comment)
          }
        
        
        return comments
    }
    
    func deleteComment(commentId: String) async throws {
        let commentRef = commentCollection.document(commentId)
        try await commentRef.delete()
    }
    
    func getComments(postId: String) async throws -> [UICommentModel] {
        
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("postId", isEqualTo: postId).whereField("parentCommentId", isEqualTo: "").limit(to: 20)
        let newDocs = try await query.getDocuments()
        
        print("NEW DOCS:", newDocs)
                                        
        for i in newDocs.documents {
              let comment = await mapItem(item: i)
              comments.append(comment)
          }
        
        print("COMMENTS: ", comments)
        
        let uiComments = try await hydrateComments(comments)
        
        return uiComments
    }
    
    func hydrateComments(_ comments: [CommentModel]) async throws -> [UICommentModel] {

        // 1. Extract unique user IDs
        let authorIds = Array(Set(comments.map { $0.authorId }))
        
        // 2. Fetch all authors in batch
        let authors = try await UserManager.shared.fetchUsers(userIds: authorIds)
        print(authors)
        let authorMap = Dictionary(uniqueKeysWithValues: authors.map { ($0.id, $0) })

        // 3. Build hydrated UI models
        let uiComments = comments.compactMap { comment -> UICommentModel? in
            guard let author = authorMap[comment.authorId] else { return nil }

            return UICommentModel(
                id: comment.id,
                comment: comment,
                author: author
            )
        }

        return uiComments
    }

    
    func updateToParent(commentId: String) async throws {
        try await commentCollection.document(commentId).updateData(["hasChildren" : true])
    }
    
    func getChildComments(postId: String, commentId: String) async throws -> [UICommentModel] {
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("postId", isEqualTo: postId).whereField("parentCommentId", isEqualTo: commentId).limit(to: 100)
        let newDocs = try await query.getDocuments()
        
        print("NEW DOCS:", newDocs)
                                        
        for i in newDocs.documents {
              let comment = await mapItem(item: i)
              comments.append(comment)
          }
        
        let uiComments = try await hydrateComments(comments)
        
        return uiComments
    }
    
    private func mapItem(item: QueryDocumentSnapshot) async -> CommentModel {
        
        let message = item["message"] as? String ?? "No Message"
        let authorId = item["authorId"] as? String ?? "Anonymous"
        let postId = item["postId"] as? String ?? "No Post Id"
        let postName = item["postName"] as? String ?? "Unnamed Post"
        let createdAt = item["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let upvotes = item["upvotes"] as? Int ?? 0
        let parentCommentId = item["parentCommentId"] as? String ?? ""
        let hasChildren = item["hasChildren"] as? Bool ?? false
        let isOnEvent = item["isOnEvent"] as? Bool ?? false
        
        return CommentModel(id: item.documentID, postId: postId, postName: postName, message: message, authorId: authorId, createdAt: createdAt, upvotes: upvotes, parentCommentId: parentCommentId, hasChildren: hasChildren, isOnEvent: isOnEvent)
    }

}
