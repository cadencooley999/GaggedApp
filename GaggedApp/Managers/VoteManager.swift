//
//  VoteManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/12/25.
//
import Foundation
import SwiftUI
import FirebaseFirestore

class VoteManager {
    
    static let shared = VoteManager()
    
    private var votesCollection: CollectionReference {
        Firestore.firestore().collection("Votes")
    }
    
    private var weekStatsCollection: CollectionReference {
        Firestore.firestore().collection("WeeklyPostStats")
    }
    
    func uploadVote(vote: VoteModel, cityIds: [String]) async throws {
        let voteRef = votesCollection.document(vote.id)

        let week = weekId()
        let statsDocId = "\(vote.postId)_\(week)"
        let statsRef = weekStatsCollection.document(statsDocId)

        try await Firestore.firestore().runTransaction { tx, _ in

            // 1️⃣ Create / update weekly aggregate
            let statsSnap = try? tx.getDocument(statsRef)

            if statsSnap?.exists != true {
                tx.setData([
                    "postId": vote.postId,
                    "week": week,
                    "weekStart": Timestamp(date: self.weekStartDate()),
                    "upvotes": vote.upvote ? 1 : 0,
                    "downvotes": vote.upvote ? 0 : 1,
                    "cityIds": cityIds
                ], forDocument: statsRef)
            } else {
                tx.updateData([
                    vote.upvote ? "upvotes" : "downvotes": FieldValue.increment(Int64(1))
                ], forDocument: statsRef)
            }

            // 2️⃣ Save vote
            tx.setData([
                "postId": vote.postId,
                "userId": vote.userId,
                "upvote": vote.upvote,
                "timestamp": FieldValue.serverTimestamp()
            ], forDocument: voteRef)

            return nil
        }
    }
    
    func deleteVote(postId: String, userId: String) async throws {
        let voteId = "\(postId)\(userId)"
        let voteRef = votesCollection.document(voteId)

        let voteSnap = try await voteRef.getDocument()
        guard let data = voteSnap.data(),
              let timestamp = data["timestamp"] as? Timestamp,
              let upvote = data["upvote"] as? Bool
        else { return }

        let week = weekId(from: timestamp.dateValue())
        let statsDocId = "\(postId)_\(week)"
        let statsRef = weekStatsCollection.document(statsDocId)

        try await Firestore.firestore().runTransaction { tx, _ in
            tx.updateData([
                upvote ? "upvotes" : "downvotes": FieldValue.increment(Int64(-1))
            ], forDocument: statsRef)

            tx.deleteDocument(voteRef)
            return nil
        }
    }
    
    func getPostVotes(postId: String) async throws -> [VoteModel] {
        var votes: [VoteModel] = []
        
        let docs = try await votesCollection.whereField("postId", isEqualTo: postId).getDocuments()
        
        for d in docs.documents {
            if let vote = mapVote(doc: d) {
                votes.append(vote)
            }
        }
        
        return votes
    }
    
    func mapVote(doc: QueryDocumentSnapshot) -> VoteModel? {
        let id = doc["id"] as? String ?? ""
        let postId = doc["postId"] as? String ?? ""
        let userId = doc["userId"] as? String ?? ""
        let timestamp = doc["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        let upvote = doc["upvote"] as? Bool ?? false

        guard !id.isEmpty else { return nil }
        
        return VoteModel(postId: postId, userId: userId, timestamp: timestamp, upvote: upvote)
    }
    
    func weekId(from date: Date = Date()) -> String {
        let calendar = Calendar(identifier: .iso8601)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    func weekStartDate(from date: Date = Date()) -> Date {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }
}
