//
//  ReportManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/26/26.
//
import Foundation
import FirebaseFirestore

struct ReportContentCursor {
    let createdAt: Timestamp
    let reportCount: Int
    let contentId: String
}

struct ReportedPost {
    var post: PostModel
    let reportReasons: [String]
}

struct ReportedPoll {
    var pollwithoptions: PollWithOptions
    let reportReasons: [String]
}

struct ReportedComment: Identifiable {
    var id: String { comment.id }
    var comment: CommentModel
    let reportReasons: [String]
}

class ReportManager {
    static let shared = ReportManager()
    
    let collectionRef = Firestore.firestore().collection("ReportedContent")
    
    func addReport(report: ReportModel) async throws {
        let reportId = "\(report.contentId)_\(report.reportAuthorId)"
        try await collectionRef.document(reportId).setData([
            "id": reportId,
            "contentType": report.contentType.rawValue,
            "contentId": report.contentId,
            "contentAuthorId": report.contentAuthorId,
            "reportAuthorId": report.reportAuthorId,
            "reason": report.reason.rawValue,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    func mapReport(document: DocumentSnapshot) -> ReportModel? {
        guard let data = document.data() else { return nil }
        
        guard
            let contentTypeRaw = data["contentType"] as? String,
            let contentType = ReportContentType(rawValue: contentTypeRaw),
            
            let contentId = data["contentId"] as? String,
            let contentAuthorId = data["contentAuthorId"] as? String,
            let reportAuthorId = data["reportAuthorId"] as? String,
            
            let reasonRaw = data["reason"] as? String,
            let reason = ReportReason(rawValue: reasonRaw),
            
            let statusRaw = data["status"] as? String,
            let status = ReportStatus(rawValue: statusRaw),
            
            let createdAt = data["createdAt"] as? Timestamp
            
        else {
            return nil
        }
        
        return ReportModel(
            id: document.documentID,
            contentType: contentType,
            contentId: contentId,
            contentAuthorId: contentAuthorId,
            reportAuthorId: reportAuthorId,
            reason: reason,
            status: status,
            createdAt: createdAt
        )
    }
    
    // MARK: - Fetching reported Posts (pending-only)
    func fetchReportedPosts(pageSize: Int = 15, cursor: ReportContentCursor?) async throws -> ([ReportedPost], ReportContentCursor?) {
        var query: Query = Firestore.firestore().collection("Posts")
            .whereField("reportCount", isGreaterThan: 0)
            .order(by: "reportCount")
            .order(by: "createdAt")
            .order(by: FieldPath.documentID())
            .limit(to: pageSize+1)
        
        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.contentId
            ])
        }
        
        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents
        let pageDocs = Array(docs.prefix(pageSize))
        let hasMore = docs.count > pageSize
        

        let reportedPosts: [ReportedPost] = pageDocs.compactMap { doc in
            var reasons = doc["reportReasons"] as? [String:Int] ?? [:]
            return ReportedPost(
                post: FirebasePostManager.shared.mapItem(item: doc),
                reportReasons: reasons.keys.filter({reasons[$0] ?? 0 > 0})
            )
        }
    
        
        let nextCursor: ReportContentCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }
            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }
            guard let reportCount = last["reportCount"] as? Int else { return nil   }
            return ReportContentCursor(createdAt: createdAt, reportCount: reportCount, contentId: last.documentID)
        }()
        
        return (reportedPosts, nextCursor)
    }
    
    // MARK: - Fetching reported Polls (by reportCount) + options
    func fetchReportedPolls(pageSize: Int = 15, cursor: ReportContentCursor?) async throws -> ([ReportedPoll], ReportContentCursor?) {
        var query: Query = Firestore.firestore().collection("Polls")
            .whereField("reportCount", isGreaterThan: 0)
            .order(by: "reportCount")
            .order(by: "createdAt")
            .order(by: FieldPath.documentID())
            .limit(to: pageSize + 1)
        
        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.contentId
            ])
        }
        
        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents
        let pageDocs = Array(docs.prefix(pageSize))
        let hasMore = docs.count > pageSize
        
        var reasonsById: [String: [String]] = [:]
        let pollIds: [String] = pageDocs.map { doc in
            let rr = doc["reportReasons"] as? [String: Int] ?? [:]
            reasonsById[doc.documentID] = rr.keys.filter { (rr[$0] ?? 0) > 0 }
            return doc.documentID
        }
        
        var polls = try await PollManager.shared.getPollsFromIds(ids: pollIds)
        let pollsById = Dictionary(uniqueKeysWithValues: polls.map { ($0.id, $0) })
        
        var optionsByPollId: [String:[PollOption]] = [:]
        
        for pollId in pollsById.keys {
            optionsByPollId[pollId] = try await PollManager.shared.fetchPollOptions(pollId: pollId)
        }

        let reportedPolls: [ReportedPoll] = pollIds.compactMap { id in
            guard let poll = pollsById[id] else { return nil }
            return ReportedPoll(pollwithoptions: PollWithOptions(id: poll.id, poll: poll.poll, options: optionsByPollId[poll.id] ?? []), reportReasons: reasonsById[id] ?? [])
        }

        let nextCursor: ReportContentCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }
            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }
            let reportCount = last["reportCount"] as? Int ?? 0
            return ReportContentCursor(createdAt: createdAt, reportCount: reportCount, contentId: last.documentID)
        }()

        return (reportedPolls, nextCursor)
    }
    
    // MARK: - Fetching reported Comments (by reportCount)
    func fetchReportedComments(pageSize: Int = 15, cursor: ReportContentCursor?) async throws -> ([ReportedComment], ReportContentCursor?) {
        var query: Query = Firestore.firestore().collection("Comments")
            .whereField("reportCount", isGreaterThan: 0)
            .order(by: "reportCount")
            .order(by: "createdAt")
            .order(by: FieldPath.documentID())
            .limit(to: pageSize + 1)

        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.contentId
            ])
        }

        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents
        let pageDocs = Array(docs.prefix(pageSize))
        let hasMore = docs.count > pageSize

        let reportedComments: [ReportedComment] = pageDocs.compactMap { doc in
            let rr = doc["reportReasons"] as? [String: Int] ?? [:]
            let reasons = rr.keys.filter { (rr[$0] ?? 0) > 0 }
            let comment = mapComment(doc)
            return ReportedComment(comment: comment, reportReasons: reasons)
        }

        let nextCursor: ReportContentCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }
            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }
            let reportCount = last["reportCount"] as? Int ?? 0
            return ReportContentCursor(createdAt: createdAt, reportCount: reportCount, contentId: last.documentID)
        }()

        return (reportedComments, nextCursor)
    }
    
    // MARK: - Helpers
    private func fetchCommentsByIds(ids: [String]) async throws -> [CommentModel] {
        guard !ids.isEmpty else { return [] }
        var results: [CommentModel] = []
        let chunks = Array(ids.prefix(100)).chunked(into: 10)
        let commentCollection = Firestore.firestore().collection("Comments")
        
        for chunk in chunks {
            let snap = try await commentCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            for doc in snap.documents {
                results.append(mapComment(doc))
            }
        }
        return results
    }
    
    func approvePost(postId: String) async throws {
        let snapShot = try await collectionRef.whereField("contentType", isEqualTo: "post").whereField("contentId", isEqualTo: postId).getDocuments()
        let batch = Firestore.firestore().batch()
        for doc in snapShot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        try await Firestore.firestore().collection("Posts").document(postId).updateData(["isHidden":false, "reportCount":0, "reportReasons":[:]])
    }

    func approveComment(commentId: String) async throws {
        let snapShot = try await collectionRef
            .whereField("contentType", isEqualTo: "comment")
            .whereField("contentId", isEqualTo: commentId)
            .getDocuments()
        let batch = Firestore.firestore().batch()
        for doc in snapShot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        try await Firestore.firestore().collection("Comments").document(commentId).updateData(["isHidden": false, "reportCount": 0, "reportReasons":[:]])
    }

    func approvePoll(pollId: String) async throws {
        let snapShot = try await collectionRef
            .whereField("contentType", isEqualTo: "poll")
            .whereField("contentId", isEqualTo: pollId)
            .getDocuments()
        let batch = Firestore.firestore().batch()
        for doc in snapShot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        try await Firestore.firestore().collection("Polls").document(pollId).updateData(["isHidden": false, "reportCount": 0, "reportReasons":[:]])
    }
    
    func deleteReports(contentId: String) async throws {
        let snapShot = try await collectionRef
            .whereField("contentId", isEqualTo: contentId)
            .getDocuments()
        let batch = Firestore.firestore().batch()
        for doc in snapShot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
    
    private func mapComment(_ item: QueryDocumentSnapshot) -> CommentModel {
        let data = item.data()
        let message = data["message"] as? String ?? "No Message"
        let authorId = data["authorId"] as? String ?? "Anonymous"
        let authorName = data["authorName"] as? String ?? "Anonymous"
        let authorProfPic = data["authorProfPic"] as? String ?? ""
        let postId = data["postId"] as? String ?? "No Post Id"
        let postName = data["postName"] as? String ?? "Unnamed Post"
        let createdAt = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let upvotes = data["upvotes"] as? Int ?? 0
        let parentCommentId = data["parentCommentId"] as? String ?? ""
        let parentAuthorId = data["parentAuthorId"] as? String ?? ""
        let parentAuthorName = data["parentAuthorName"] as? String ?? ""
        let ancestorId = data["ancestorId"] as? String ?? ""
        let hasChildren = data["hasChildren"] as? Bool ?? false
        let isOnEvent = data["isOnEvent"] as? Bool ?? false
        let isGrand = data["isGrand"] as? Bool ?? false
        
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

