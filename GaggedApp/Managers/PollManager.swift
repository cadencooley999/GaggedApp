//
//  PollManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/17/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

enum PollManagerError: Error { case invalidId, invalidCityIds, documentNotFound }

struct PollFeedCursor: Codable, Equatable {
    let createdAtSeconds: TimeInterval   // unix seconds or ms (match server)
    let pollId: String
}

struct PollCursor {
    let createdAt: Timestamp
    let pollId: String
}

struct PollFeedReturn: Codable {
    let polls: [PollWithOptions]
    let nextCursor: PollFeedCursor?
}

class PollManager {
    static let shared = PollManager()
    
    let functions = Functions.functions()
    
    private var pollCollection: CollectionReference {
        Firestore.firestore().collection("Polls")
    }
    
    func addPoll(poll: PollModel, options: [PollOption]) async throws {
        let pollRef = pollCollection.document()
        let pollId = pollRef.documentID
        
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        
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
            "cityId" : poll.cityId,
            "isHidden" : false,
            "reportCount" : 0,
            "reportReasons" : [],
            "expiresAt": Timestamp(date: threeMonthsFromNow)
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
    
    func deletePoll(pollId: String) async throws {
        guard !pollId.isEmpty else {
            throw PollManagerError.invalidId
        }

        let pollRef = pollCollection.document(pollId)
        
        try await pollRef.delete()
    }
    
    func fetchGlobalPollFeed(pageSize: Int = 15, cursor: PollCursor?) async throws -> ([PollWithOptions], PollCursor?) {
        var query: Query = pollCollection.order(by: "createdAt").order(by: "id").limit(to: pageSize+1)
        
        print("in fetch global poll feed")
        
        if let cursor {
            print(
                "cursor == ", cursor
            )
            query = query.start(after: [
                cursor.createdAt,
                cursor.pollId
            ])
        }
        
        let docs = try await query.getDocuments()
        let pageDocs = docs.documents.prefix(pageSize)
        let hasMore = docs.count > pageSize
        let mapped = pageDocs.map {PollWithOptions(id: $0.documentID, poll: mapPoll(document: $0), options: [])}
        
        let nextCursor: PollCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }

            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }

            return PollCursor(
                createdAt: createdAt,
                pollId: last.documentID
            )
        }()
        
        return (mapped, nextCursor)
    }

    
    func fetchPolls(cityIds: [String], pageSize: Int = 5, cursor: PollFeedCursor?) async throws -> PollFeedReturn {
        guard !cityIds.isEmpty else { return PollFeedReturn(polls: [], nextCursor: nil) }
        
        var results: [PollWithOptions] = []
        
        let newCityIds = cityIds.prefix(50)

        var payload: [String: Any] = [
            "cityIds": newCityIds.compactMap({$0}),
            "pageSize": pageSize
        ]

        if let cursor {
            payload["cursor"] = [
                "createdAtSeconds": Double(cursor.createdAtSeconds), // MUST be Double
                "pollId": String(cursor.pollId)
            ]
        }
        
        print("Sending cursor:", payload["cursor"] ?? "nil")
        
        let result = try await functions
            .httpsCallable("getPollFeed")
            .call(payload)
        
        guard let dict = result.data as? [String: Any] else {
            return PollFeedReturn(polls: [], nextCursor: nil)
        }

        let polls = decodePolls(from: dict)
        let cursor = dict["nextCursor"] as? [String: Any]
        let nextCursor = decodeCursor(from: dict)
        print("Fetching Polls (chunked)")
        
        for poll in polls {
            let options = try await fetchPollOptions(pollId: poll.id)
            results.append(
                PollWithOptions(
                    id: poll.id,
                    poll: poll,
                    options: options
                )
            )
        }

        return PollFeedReturn(polls: results, nextCursor: nextCursor)
    }
    
    func decodePolls(from result: Any) -> [PollModel] {
        guard
            let dict = result as? [String: Any],
            let rawPolls = dict["polls"] as? [[String: Any]]
        else {
            return []
        }

        return rawPolls.compactMap { pollDict in
            guard let id = pollDict["id"] as? String else { return nil}
            return mapPoll(id: id, data: pollDict)
        }
    }
    
    private func mapPoll(
        id: String,
        data: [String: Any]
    ) -> PollModel? {

        // Required fields (fail fast if missing)
        guard
            let title = data["title"] as? String,
            let cityId = data["cityId"] as? String
        else {
            return nil
        }

        // Optional / defaulted fields
        let context = data["context"] as? String ?? ""
        let authorId = data["authorId"] as? String ?? ""
        let authorName = data["authorName"] as? String ?? ""
        let authorPicUrl = data["authorPicUrl"] as? String ?? ""

        let linkedPostId = data["linkedPostId"] as? String ?? ""
        let linkedPostName = data["linkedPostName"] as? String ?? ""

        let optionsCount = data["optionsCount"] as? Int ?? 0
        let totalVotes = data["totalVotes"] as? Int ?? 0

        let keywords = data["keywords"] as? [String] ?? []

        // createdAt normalization (same logic as posts)
        let createdAt: Timestamp
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts
        }
        else if let seconds = data["createdAt"] as? TimeInterval {
            createdAt = Timestamp(seconds: Int64(seconds), nanoseconds: 0)
        }
        else if let dict = data["createdAt"] as? [String: Any],
                let seconds = dict["_seconds"] as? Int64 {
            createdAt = Timestamp(seconds: seconds, nanoseconds: 0)
        }
        else {
            // Polls MUST have createdAt — drop if missing
            return nil
        }

        return PollModel(
            id: id,
            authorId: authorId,
            authorName: authorName,
            authorPicUrl: authorPicUrl,
            title: title,
            context: context,
            linkedPostId: linkedPostId,
            linkedPostName: linkedPostName,
            optionsCount: optionsCount,
            totalVotes: totalVotes,
            createdAt: createdAt,
            cityId: cityId,
            keywords: keywords
        )
    }

    
    func decodeCursor(from result: Any) -> PollFeedCursor? {
        guard
            let dict = result as? [String: Any],
            let rawCursor = dict["nextCursor"]
        else {
            return nil
        }

        // End of pagination (expected)
        if rawCursor is NSNull {
            return nil
        }

        guard
            let cursor = rawCursor as? [String: Any],
            let pollId = cursor["pollId"] as? String,
            let createdAtSeconds = cursor["createdAtSeconds"] as? TimeInterval
        else {
            print("Cursor malformed:", rawCursor)
            return nil
        }

        return PollFeedCursor(
            createdAtSeconds: createdAtSeconds,
            pollId: pollId
        )
    }
    
    func fetchPollById(id: String) async throws -> PollWithOptions {
        let document = try await pollCollection.document(id).getDocument()
        let poll = mapPollDoc(document: document)
        let options = try await fetchPollOptions(pollId: id)
        print("Found everything")
        return PollWithOptions(id: poll.id, poll: poll, options: options)
    }
    
    func fetchAllPollsNearby(cityIds: [String]) async throws -> [PollWithOptions] {
        guard !cityIds.isEmpty else { return [] }
        print("Fetching Polls (chunked)")

        let chunks = cityIds.chunked(into: 10)
        var results: [PollWithOptions] = []

        for chunk in chunks {
            let snapshot = try await pollCollection
                .whereField("cityId", in: chunk)
                .whereField("isHidden", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            for document in snapshot.documents {
                let poll = mapPoll(document: document)
                let options = try await fetchPollOptions(pollId: poll.id)
                results.append(
                    PollWithOptions(
                        id: poll.id,
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
        guard !pollId.isEmpty else { return [] }
        let ref = pollCollection.document(pollId)
        let snap = try await ref.getDocument()
        guard snap.exists else { return [] }
        let snapshot = try await ref
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
    
    func getGlobalPollsFromSearch(keyword: String) async throws -> [PollWithOptions] {
        let tokens = keyword
            .lowercased()
            .split(separator: " ")
            .map { String($0) }

        guard let first = tokens.first else {return []}

        let snapshot = try await pollCollection
            .whereField("keywords", arrayContains: first)
            .whereField("isHidden", isEqualTo: false)
            .limit(to: 50)
            .getDocuments()

        let polls = snapshot.documents.map {PollWithOptions(id: $0.documentID, poll: mapPoll(document: $0), options: [])}

        let filtered = polls.filter { poll in
            let tokenSet = Set(poll.poll.keywords)
            return tokens.allSatisfy { tokenSet.contains($0) }
        }

        return filtered
    }
    
    func addPollVote(pollId: String, optionId: String) async throws {
        guard !pollId.isEmpty, !optionId.isEmpty else { throw PollManagerError.invalidId }
        let pollRef = pollCollection.document(pollId)
        let pollSnap = try await pollRef.getDocument()
        guard pollSnap.exists else { throw PollManagerError.documentNotFound }
        let optionRef = pollRef.collection("options").document(optionId)
        let optionSnap = try await optionRef.getDocument()
        guard optionSnap.exists else { throw PollManagerError.documentNotFound }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await pollRef.updateData(["totalVotes":FieldValue.increment(Int64(1)), "expiresAt":Timestamp(date: threeMonthsFromNow)])
        try await optionRef.updateData(["voteCount" : FieldValue.increment(Int64(1))])
    }
    
    func removePollVote(pollId: String, optionId: String) async throws {
        guard !pollId.isEmpty, !optionId.isEmpty else { throw PollManagerError.invalidId }
        let pollRef = pollCollection.document(pollId)
        let pollSnap = try await pollRef.getDocument()
        guard pollSnap.exists else { throw PollManagerError.documentNotFound }
        let optionRef = pollRef.collection("options").document(optionId)
        let optionSnap = try await optionRef.getDocument()
        guard optionSnap.exists else { throw PollManagerError.documentNotFound }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await pollRef.updateData(["totalVotes":FieldValue.increment(Int64(-1)), "expiresAt":Timestamp(date: threeMonthsFromNow)])
        try await optionRef.updateData(["voteCount" : FieldValue.increment(Int64(-1))])
    }
    
    func switchVote(pollId: String, oldOptionId: String, newOptionId: String) async throws {
        guard !pollId.isEmpty, !oldOptionId.isEmpty, !newOptionId.isEmpty else { throw PollManagerError.invalidId }
        let pollRef = pollCollection.document(pollId)
        let pollSnap = try await pollRef.getDocument()
        guard pollSnap.exists else { throw PollManagerError.documentNotFound }
        let oldRef = pollRef.collection("options").document(oldOptionId)
        let newRef = pollRef.collection("options").document(newOptionId)
        let oldSnap = try await oldRef.getDocument()
        let newSnap = try await newRef.getDocument()
        guard oldSnap.exists, newSnap.exists else { throw PollManagerError.documentNotFound }
        try await oldRef.updateData(["voteCount":FieldValue.increment(Int64(-1))])
        try await newRef.updateData(["voteCount":FieldValue.increment(Int64(1))])
    }
    
    func getUserPolls(
        uid: String,
        pageSize: Int = 5,
        cursor: PollCursor?
    ) async throws -> ([PollWithOptions], PollCursor?) {

        guard !uid.isEmpty else { return ([], nil) }

        var query: Query = pollCollection
            .whereField("authorId", isEqualTo: uid)
            .whereField("isHidden", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .order(by: FieldPath.documentID())
            .limit(to: pageSize + 1)

        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.pollId
            ])
        }

        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents

        let hasMore = docs.count > pageSize
        let pageDocs = Array(docs.prefix(pageSize))

        let polls: [PollWithOptions] = pageDocs.map { doc in
            let poll = mapPoll(document: doc)
            return PollWithOptions(id: poll.id, poll: poll, options: [])
        }

        let nextCursor: PollCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }

            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }

            return PollCursor(
                createdAt: createdAt,
                pollId: last.documentID
            )
        }()

        return (polls, nextCursor)
    }
    
    func getPollsFromIds(ids: [String]) async throws -> [PollWithOptions] {
        guard !ids.isEmpty else { return [] }
        var results: [PollWithOptions] = []
        let chunks = Array(ids.prefix(100)).chunked(into: 10)

        for chunk in chunks {
            let snapshot = try await pollCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            for doc in snapshot.documents { // QueryDocumentSnapshot
                let poll = mapPoll(document: doc) // use the QueryDocumentSnapshot overload
                results.append(PollWithOptions(id: poll.id, poll: poll, options: []))
            }
        }
        return results
    }
    
    func incrementReports(pollId: String) async throws {
        try await pollCollection.document(pollId).updateData(["reportCount": FieldValue.increment(Int64(1))])
    }

    func mapPoll(document: QueryDocumentSnapshot) -> PollModel {
        let data = document.data()
    
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
    
    func mapPollDoc(document: DocumentSnapshot) -> PollModel {
        guard let data = document.data() else {
            // Return an empty/default PollModel if data is missing
            return PollModel(
                id: document.documentID,
                authorId: "",
                authorName: "",
                authorPicUrl: "",
                title: "",
                context: "",
                linkedPostId: "",
                linkedPostName: "",
                optionsCount: 0,
                totalVotes: 0,
                createdAt: Timestamp(),
                cityId: "",
                keywords: []
            )
        }

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
        let inputs = [authorName, String(question.prefix(20)), linkedName]
        
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

