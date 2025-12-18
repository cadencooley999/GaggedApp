//
//  VoteModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/12/25.
//

import FirebaseFirestore

struct VoteModel: Identifiable {
    let postId: String
    let userId: String
    let timestamp: Timestamp?
    let upvote: Bool
    
    var id: String {
        return postId+userId
    }
}

struct WeeklyPostStat: Identifiable, Hashable, Comparable {
    let id: String           
    let postId: String
    let week: String
    let weekStart: Timestamp
    let upvotes: Int
    let downvotes: Int
    let cityIds: [String]
    
    static func < (lhs: WeeklyPostStat, rhs: WeeklyPostStat) -> Bool {
        if lhs.upvotes != rhs.upvotes {
            return lhs.upvotes < rhs.upvotes
        }
        // Tie-breaker to keep ordering stable
        return lhs.postId < rhs.postId
    }


    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()

        guard
            let postId = data["postId"] as? String,
            let week = data["week"] as? String,
            let weekStart = data["weekStart"] as? Timestamp,
            let upvotes = data["upvotes"] as? Int,
            let downvotes = data["downvotes"] as? Int,
            let cityIds = data["cityIds"] as? [String]
        else {
            return nil
        }

        self.id = doc.documentID
        self.postId = postId
        self.week = week
        self.weekStart = weekStart
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.cityIds = cityIds
    }
}

