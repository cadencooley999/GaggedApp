//
//  PollManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/17/25.
//

import Foundation
import FirebaseFirestore

class PollManager {
    static let shared = PollManager()
    
    private var pollCollection: CollectionReference {
        Firestore.firestore().collection("Polls")
    }
    
    func addPoll(poll: PollModel, options: [PollOption]) async throws {
        let pollRef = pollCollection.document()
        let pollId = pollRef.documentID
        
        try await pollRef.setData([
            "id": pollId,
            "title" : poll.title,
            "context" : poll.context,
            "authorId" : poll.authorId,
            "totalVotes" : poll.totalVotes,
            "optionsCount" : poll.optionsCount,
            "createdAt" : poll.createdAt,
            "keywords" : generateKeywords(title: poll.title, name: poll.postId),
            "postId" : poll.postId,
            "cityId" : poll.cityId
        ])
        
        let db = Firestore.firestore()
        let batch = db.batch()
        let optionsRef = pollRef.collection("options")
        
        for option in options {
            let optionRef = optionsRef.document()
            batch.setData([
                "id":optionRef.documentID,
                "text": option.text,
                "voteCount": 0,
                "index": option.index
            ], forDocument: optionRef)
        }
        
        try await batch.commit()
    }
    
    func generateKeywords(title: String, name: String) -> [String] {
        let inputs = [title, name]
        
        var keywords: [String] = []
        
        for input in inputs {
            // Split each word in case the title or name has spaces (e.g., "Swift UI")
            let parts = input.lowercased().split(separator: " ")
            
            for part in parts {
                var prefix = ""
                for char in part {
                    prefix.append(char)
                    keywords.append(prefix)
                }
            }
        }
        
        return keywords
    }
}
