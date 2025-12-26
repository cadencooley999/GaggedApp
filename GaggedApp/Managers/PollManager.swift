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
            "authorName" : poll.authorName,
            "authorPicUrl" : poll.authorPicUrl,
            "totalVotes" : poll.totalVotes,
            "optionsCount" : poll.optionsCount,
            "createdAt" : poll.createdAt,
            "keywords" : generateKeywords(authorName: poll.authorName, question: poll.title, linkedName: poll.linkedPostName),
            "linkedPostId" : poll.linkedPostId,
            "linkedPostName" : poll.linkedPostName,
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
    
    func fetchPolls(cityIds: [String]) async throws -> [PollWithOptions] {
        print("Fetching Polls (chunked)")

        let chunks = cityIds.chunked(into: 10)
        var results: [PollWithOptions] = []

        for chunk in chunks {
            let snapshot = try await pollCollection
                .whereField("cityId", in: chunk)
                .order(by: "createdAt", descending: true)
                .limit(to: 10)
                .getDocuments()

            for document in snapshot.documents {
                let poll = mapPoll(document: document)
                let options = try await fetchPollOptions(pollId: poll.id)
                results.append(
                    PollWithOptions(
                        poll: poll,
                        options: options
                    )
                )
            }
        }

        // 🔑 Global ordering after merging chunks
        results.sort {
            $0.poll.createdAt.seconds > $1.poll.createdAt.seconds
        }

        return results
    }
    
    func fetchAllPollsNearby(cityIds: [String]) async throws -> [PollWithOptions] {
        print("Fetching Polls (chunked)")

        let chunks = cityIds.chunked(into: 10)
        var results: [PollWithOptions] = []

        for chunk in chunks {
            let snapshot = try await pollCollection
                .whereField("cityId", in: chunk)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            for document in snapshot.documents {
                let poll = mapPoll(document: document)
                let options = try await fetchPollOptions(pollId: poll.id)
                results.append(
                    PollWithOptions(
                        poll: poll,
                        options: options
                    )
                )
            }
        }

        // 🔑 Global ordering after merging chunks
        results.sort {
            $0.poll.createdAt.seconds > $1.poll.createdAt.seconds
        }

        return results
    }
    
    func fetchPollOptions(pollId: String) async throws -> [PollOption] {
        let snapshot = try await pollCollection
            .document(pollId)
            .collection("options")
            .order(by: "index")
            .getDocuments()

        return snapshot.documents.map { doc in
            let data = doc.data()
            return PollOption(
                id: data["id"] as? String ?? "",
                text: data["text"] as? String ?? "",
                voteCount: data["voteCount"] as? Int ?? 0,
                index: data["index"] as? Int ?? 0
            )
        }
    }
    
    func getPollsFromSearch(keyword: String, allPollsNearby: [PollWithOptions]) -> [PollWithOptions] {

        return allPollsNearby.filter { poll in
            let lower = keyword.lowercased()
            
            // 1. Match post name
            if poll.poll.title.lowercased().contains(lower) { return true }
            
            if poll.poll.authorName.lowercased().contains(lower) { return true }
            
            if poll.poll.linkedPostName.lowercased().contains(lower) { return true }
            
            // 3. Match city names
            let cities = CityManager.shared.getCities(ids: [poll.poll.cityId])
            if cities.contains(where: { $0.city.lowercased().contains(lower) }) {
                return true
            }
            
            return false
        }
    }
    
    func addPollVote(pollId: String, optionId: String) async throws {
        try await pollCollection.document(pollId).updateData(["totalVotes":FieldValue.increment(Int64(1))])
        try await pollCollection.document(pollId).collection("options").document(optionId).updateData(["voteCount" : FieldValue.increment(Int64(1))])
    }
    
    func removePollVote(pollId: String, optionId: String) async throws {
        try await pollCollection.document(pollId).updateData(["totalVotes":FieldValue.increment(Int64(-1))])
        try await pollCollection.document(pollId).collection("options").document(optionId).updateData(["voteCount" : FieldValue.increment(Int64(-1))])
    }
    
    func switchVote(pollId: String, oldOptionId: String, newOptionId: String) async throws {
        try await pollCollection.document(pollId).collection("options").document(oldOptionId).updateData(["voteCount":FieldValue.increment(Int64(-1))])
        try await pollCollection.document(pollId).collection("options").document(newOptionId).updateData(["voteCount":FieldValue.increment(Int64(1))])
    }

    func mapPoll(document: QueryDocumentSnapshot) -> PollModel {
        let data = document.data()
        
        print("mapping")

        return PollModel(
            id: document.documentID,
            authorId: data["authorId"] as? String ?? "",
            authorName: data["authorName"] as? String ?? "",
            authorPicUrl: data["authorPicUrl"] as? String ?? "",
            title: data["title"] as? String ?? "",
            context: data["context"] as? String ?? "",
            linkedPostId: data["linkedPostId"] as? String ?? "",
            linkedPostName: data["linkedPostName"] as? String ?? "",
            optionsCount: data["optionsCount"] as? Int ?? 0,
            totalVotes: data["totalVotes"] as? Int ?? 0,
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
            cityId: data["cityId"] as? String ?? "",
            keywords: data["keywords"] as? [String] ?? []
        )
    }
    
    func generateKeywords(authorName: String, question: String, linkedName: String) -> [String] {
        let inputs = [authorName, String(question.prefix(5)), linkedName]
        
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
