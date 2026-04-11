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

struct CommentsCursor: Codable, Equatable {
    let createdAt: Timestamp
    let commentId: String
}

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
            "createdAt" : FieldValue.serverTimestamp(),
            "upvotes" : comment.upvotes,
            "parentCommentId" : comment.parentCommentId,
            "parentAuthorId" : comment.parentAuthorId,
            "parentAuthorName" : comment.parentAuthorName,
            "ancestorId" : comment.ancestorId,
            "hasChildren" : comment.hasChildren,
            "isOnEvent" : comment.isOnEvent,
            "isGrand" : comment.isGrand,
            "isHidden" : false,
            "reportCount" : 0,
            "reportReasons" : []
        ])
        Task {
            try await FirebasePostManager.shared.updateExpiry(postId: comment.postId)
        }
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
    
    func getUserComments(
        userId: String,
        pageSize: Int = 5,
        blockedUserIds: [String] = [],
        cursor: CommentsCursor?
    ) async throws -> ([CommentModel], CommentsCursor?) {

        guard !userId.isEmpty else { return ([], nil) }

        let fetchLimit = pageSize + 1   // 👈 overfetch

        var query = commentCollection
            .whereField("authorId", isEqualTo: userId)
            .whereField("isHidden", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .order(by: FieldPath.documentID())
            .limit(to: fetchLimit)

        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.commentId
            ])
        }

        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents

        let hasMore = docs.count > pageSize
        let pageDocs = Array(docs.prefix(pageSize))

        let comments = pageDocs.map { mapItem(item: $0) }
        let filtered = comments.filter { !blockedUserIds.contains($0.authorId) }

        let nextCursor: CommentsCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }

            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }

            return CommentsCursor(
                createdAt: createdAt,
                commentId: last.documentID
            )
        }()

        return (filtered, nextCursor)
    }

    
    func deleteComment(commentId: String) async throws {
        guard !commentId.isEmpty else { throw CommentsManagerError.invalidId }
        let ref = commentCollection.document(commentId)
        let snap = try await ref.getDocument()
        guard snap.exists else { return }
        try await ref.delete()
    }
    
    func getRootComments(postId: String, limit: Int, blockedUserIds: [String] = [], cursor: CommentsCursor?) async throws -> ([CommentModel], CommentsCursor?){
        guard !postId.isEmpty else { return ([], nil) }
        
        var comments: [CommentModel] = []
        
        var query: Query = commentCollection
            .whereField("postId", isEqualTo: postId)
            .whereField("isHidden", isEqualTo: false)
            .whereField("ancestorId", isEqualTo: "")
            .order(by: "createdAt", descending: false)
            .order(by: FieldPath.documentID())
            .limit(to: limit + 1)
        
        if let cursor = cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.commentId
            ])
        }
        
        let newDocs = try await query.getDocuments()
        let pagedDocs = newDocs.documents.prefix(limit)
        let hasMore = newDocs.count > limit
        
        comments = pagedDocs.map {mapItem(item: $0)}
        let filtered = comments.filter { !blockedUserIds.contains($0.authorId) }
        
        let nextCursor: CommentsCursor? = {
            guard hasMore, let last = pagedDocs.last else { return nil }

            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }

            return CommentsCursor(
                createdAt: createdAt,
                commentId: last.documentID
            )
        }()
                        
        return (filtered, nextCursor)
    }
    
    func fetchChildren(ancestorId: String, limit: Int, blockedUserIds: [String] = [], cursor: CommentsCursor?) async throws -> ([CommentModel], CommentsCursor?) {
        guard !ancestorId.isEmpty else { return ([], nil)}
        
        var comments: [CommentModel] = []
        
        var query: Query = commentCollection
            .whereField("ancestorId", isEqualTo: ancestorId)
            .whereField("isHidden", isEqualTo: false)
            .order(by: "createdAt", descending: false)
            .order(by: FieldPath.documentID())
            .limit(to: limit + 1)
        
        if let cursor = cursor {
            print(cursor, "cursor children")
            query = query.start(after: [
                cursor.createdAt,
                cursor.commentId
            ])
        }
        
        let newDocs = try await query.getDocuments()
        let pageDocs = newDocs.documents.prefix(limit)
        let hasMore = newDocs.count > limit
        comments = pageDocs.map {mapItem(item: $0)}
        let filtered = comments.filter { !blockedUserIds.contains($0.authorId) }
        
        let nextCursor: CommentsCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }

            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }

            return CommentsCursor(
                createdAt: createdAt,
                commentId: last.documentID
            )
        }()
        
        return (filtered, nextCursor)
    }
    
    func updateToParent(commentId: String) async throws {
        guard !commentId.isEmpty else { throw CommentsManagerError.invalidId }
        let ref = commentCollection.document(commentId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw CommentsManagerError.documentNotFound }
        try await ref.updateData(["hasChildren" : true])
    }
    
    func getChildComments(postId: String, commentId: String, blockedUserIds: [String] = []) async throws -> [CommentModel] {
        guard !postId.isEmpty, !commentId.isEmpty else { return [] }
        var comments: [CommentModel] = []
        
        let query: Query = commentCollection.whereField("postId", isEqualTo: postId).whereField("isHidden", isEqualTo: false).whereField("parentCommentId", isEqualTo: commentId).limit(to: 100)
        let newDocs = try await query.getDocuments()
        
        print("NEW DOCS:", newDocs)
                                        
        for i in newDocs.documents {
              let comment = mapItem(item: i)
              comments.append(comment)
          }
        
        return comments.filter { !blockedUserIds.contains($0.authorId) }
    }
    
    func incrementReports(commentId: String) async throws {
        try await commentCollection.document(commentId).updateData(["reportCount": FieldValue.increment(Int64(1))])
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
        let parentAuthorId = item["parentAuthorId"] as? String ?? ""
        let parentAuthorName = item["parentAuthorName"] as? String ?? ""
        let ancestorId = item["ancestorId"] as? String ?? ""
        let hasChildren = item["hasChildren"] as? Bool ?? false
        let isOnEvent = item["isOnEvent"] as? Bool ?? false
        let isGrand = item["isGrand"] as? Bool ?? false
        
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
            parentAuthorId: parentAuthorId,
            parentAuthorName: parentAuthorName,
            ancestorId: ancestorId,
            hasChildren: hasChildren,
            isOnEvent: isOnEvent,
            isGrand: isGrand
        )
    }

}
