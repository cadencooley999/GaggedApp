//
//  PostManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/3/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFunctions

struct FeedCursor: Codable, Equatable {
    let createdAtSeconds: TimeInterval   // unix seconds or ms (match server)
    let postId: String
}

struct FeedResponse: Codable {
    let posts: [PostModel]
    let nextCursor: FeedCursor?
}

struct ProperPostsCursor {
    let createdAt: Timestamp
    let postId: String
}

struct UpvotedPostsCursor {
    let createdAtSeconds: TimeInterval
    let postId: String
}

enum PostManagerError: Error { case invalidId, invalidCityIds, documentNotFound }

class FirebasePostManager {
    
    static let shared = FirebasePostManager()
    
    let functions = Functions.functions()
    
    private var postsCollection: CollectionReference {
        Firestore.firestore().collection("Posts")
    }
    
    func uploadPost(post: PostModel, postRef: DocumentReference) async throws {
        
        let postId = postRef.documentID
        
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        
        try await postRef.setData([
            "id": postId,
            "text": post.text,
            "imageUrl": post.imageUrl,
            "authorId": post.authorId,
            "authorName": post.authorName,
            "authorPicUrl": post.authorPicUrl,
            "name" : post.name,
            "createdAt" : post.createdAt,
            "cityIds" : post.cityIds,
            "tags" : post.tags,
            "keywords" : generateKeywords(authorName: post.authorName, subjectName: post.name, captionPrefix: post.text, tags: post.tags, cities: CityManager.shared.getCities(ids: post.cityIds).map({$0.city})),
            "upvotes" : post.upvotes,
            "downvotes" : post.downvotes,
            "notifiedThresholds": [
                "10" : false,
                "50" : false,
                "100" : false
            ],
            "titlePrefixes" : generatePrefixes(from: post.name),
            "isHidden" : true,
            "reportCount" : 0,
            "reportReasons" : [],
            "expiresAt" : Timestamp(date: threeMonthsFromNow),
            "uploadState" : "uploading"
        ])
    }
    
    func finalizePost(postId: String, imageUrl: String) async throws {
        try await postsCollection.document(postId).updateData([
            "imageUrl" : imageUrl,
            "uploadState" : "complete",
            "isHidden":false
        ])
    }
    
    func deletePost(postId: String) async throws {
        guard !postId.isEmpty else { throw PostManagerError.invalidId }
        let ref = postsCollection.document(postId)
        let snap = try await ref.getDocument()
        guard snap.exists else { return }
        try await ref.delete()
    }
    
    func fetchHomeFeed(
        cityIds: [String],
        pageSize: Int = 10,
        blockedUserIds: [String],
        cursor: FeedCursor?
    ) async throws -> FeedResponse {
        
        let newCityIds = cityIds.prefix(50)

        var payload: [String: Any] = [
            "cityIds": newCityIds.compactMap({$0}),
            "pageSize": pageSize
        ]

        if let cursor {
            payload["cursor"] = [
                "createdAtSeconds": Double(cursor.createdAtSeconds), // MUST be Double
                "postId": String(cursor.postId)
            ]
        }
        
        print("Sending cursor:", payload["cursor"] ?? "nil")
        
        let result = try await functions
            .httpsCallable("getHomeFeed")
            .call(payload)
        
        guard let dict = result.data as? [String: Any] else {
            return FeedResponse(posts: [], nextCursor: nil)
        }

        let posts = decodePosts(from: dict)
        let filteredPosts = posts.filter { !blockedUserIds.contains($0.authorId) }
        let nextCursor = decodeCursor(from: dict)

        return FeedResponse(
            posts: filteredPosts,
            nextCursor: nextCursor
        )
    }
    
    func fetchGlobalFeed(pageSize: Int = 10, blockedUserIds: [String] = [], cursor: ProperPostsCursor?) async throws -> ([PostModel], ProperPostsCursor?) {        
        var query: Query = postsCollection.order(by: "createdAt").order(by: "id").whereField("isHidden", isEqualTo: false).limit(to: pageSize + 1)
        
        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.postId
            ])
        }
        
        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents
        
        print("docs", docs.map({$0.documentID}))

        let hasMore = docs.count > pageSize
        let pageDocs = Array(docs.prefix(pageSize))

        let posts = pageDocs.map { mapItem(item: $0) }

        let nextCursor: ProperPostsCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }
            guard let createdAt = last["createdAt"] as? Timestamp else {return nil}
            return ProperPostsCursor(
                createdAt: createdAt,
                postId: last.documentID
            )
        }()
        
        let filteredPosts = posts.filter { !blockedUserIds.contains($0.authorId) }
        return (filteredPosts, nextCursor)
    }
    
    func getPosts(from cityIDs: [String], blockedUserIds: [String] = []) async throws -> [PostModel] {
        guard !cityIDs.isEmpty else { return [] }
        
        // Break into batches of 10 per Firestore rule
        let batches = cityIDs.chunked(into: 10)
        
        var allPosts: [PostModel] = []
        var seen: Set<String> = []   // Avoid duplicate posts
        
        for batch in batches {
            let query = postsCollection
                .whereField("cityIds", arrayContainsAny: batch)
                .whereField("isHidden", isEqualTo: false)
                .limit(to: 20)
            
            let snapshot = try await query.getDocuments()
            
            for doc in snapshot.documents {
                let post = mapItem(item: doc)
                
                // Avoid duplicates if multiple batches matched it
                if seen.insert(post.id).inserted {
                    allPosts.append(post)
                }
            }
        }
        
        return allPosts.filter { !blockedUserIds.contains($0.authorId) }
    }

    func getPost(id: String) async throws -> PostModel {
        guard !id.isEmpty else { throw PostManagerError.invalidId }
        let doc = try await postsCollection.document(id).getDocument()
        guard doc.exists else { throw PostManagerError.documentNotFound }
        return mapItem(item: doc)
    }
    
    func getUserPosts(
        uid: String,
        pageSize: Int = 15,
        blockedUserIds: [String] = [],
        cursor: ProperPostsCursor?
    ) async throws -> ([PostModel], ProperPostsCursor?) {

        guard !uid.isEmpty else { return ([], nil) }

        var query = postsCollection
            .whereField("authorId", isEqualTo: uid)
            .whereField("isHidden", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .order(by: FieldPath.documentID())
            .limit(to: pageSize + 1)

        if let cursor {
            query = query.start(after: [
                cursor.createdAt,
                cursor.postId
            ])
        }

        let snapshot = try await query.getDocuments()
        let docs = snapshot.documents

        let hasMore = docs.count > pageSize
        let pageDocs = Array(docs.prefix(pageSize))

        let posts = pageDocs.map { mapItem(item: $0) }

        let nextCursor: ProperPostsCursor? = {
            guard hasMore, let last = pageDocs.last else { return nil }
            guard let createdAt = last["createdAt"] as? Timestamp else { return nil }
            return ProperPostsCursor(
                createdAt: createdAt,
                postId: last.documentID
            )
        }()

        let filteredPosts = posts.filter { !blockedUserIds.contains($0.authorId) }
        return (filteredPosts, nextCursor)
    }
    
    
    func upvotePost(postId: String) async throws {
        guard !postId.isEmpty else { throw PostManagerError.invalidId }
        let ref = postsCollection.document(postId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw PostManagerError.documentNotFound }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await ref.updateData(["upvotes": FieldValue.increment(Int64(1)), "expiresAt":threeMonthsFromNow])
    }
    
    func removeUpvote(postId: String) async throws {
        guard !postId.isEmpty else { throw PostManagerError.invalidId }
        let ref = postsCollection.document(postId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw PostManagerError.documentNotFound }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await ref.updateData(["upvotes": FieldValue.increment(Int64(-1)), "expiresAt":threeMonthsFromNow])
    }
    
    func downvotePost(postId: String) async throws {
        guard !postId.isEmpty else { throw PostManagerError.invalidId }
        let ref = postsCollection.document(postId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw PostManagerError.documentNotFound }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await ref.updateData(["downvotes": FieldValue.increment(Int64(1)), "expiresAt":threeMonthsFromNow])
    }
    
    func removeDownvote(postId: String) async throws {
        guard !postId.isEmpty else { throw PostManagerError.invalidId }
        let ref = postsCollection.document(postId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw PostManagerError.documentNotFound }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await ref.updateData(["downvotes": FieldValue.increment(Int64(-1)), "expiresAt":threeMonthsFromNow])
    }
    
    func getAllPostsNearby(cities: [String], blockedUserIds: [String] = []) async throws -> [PostModel] {
        guard !cities.isEmpty else { return [] }
        var results: [PostModel] = []
        var seen: Set<String> = []

        let chunks = cities.chunked(into: 10)

        for chunk in chunks {
            let query = postsCollection
                .whereField("isHidden", isEqualTo: false)
                .whereField("cityIds", arrayContainsAny: chunk)

            let snapshot = try await query.getDocuments()
            for doc in snapshot.documents {
                let post = mapItem(item: doc)
                if seen.insert(post.id).inserted {
                    results.append(post)
                }
            }
        }
        return results.filter { !blockedUserIds.contains($0.authorId) }
    }
    
    func getPostsFromSearch(keyword: String, allPostsNearby: [PostModel], blockedUserIds: [String] = []) -> [PostModel] {
        let results = allPostsNearby.filter { post in
            var lower = keyword.lowercased()
            lower = lower.replacingOccurrences(of: "#", with: "")
            if post.keywords.contains(lower) { return true }
            let cities = CityManager.shared.getCities(ids: post.cityIds)
            if cities.contains(where: { $0.city.lowercased().contains(lower) }) {
                return true
            }
            return false
        }
        return results.filter { !blockedUserIds.contains($0.authorId) }
    }
    
    func getGlobalPostsFromSearch(keyword: String, blockedUserIds: [String] = []) async throws -> [PostModel] {
        let tokens = keyword
            .lowercased()
            .split(separator: " ")
            .map { String($0) }
        
        print(tokens)

        guard let first = tokens.first else {
            return []
        }

        let snapshot = try await postsCollection
            .whereField("keywords", arrayContains: first)
            .whereField("isHidden", isEqualTo: false)
            .limit(to: 50)
            .getDocuments()

        let posts = snapshot.documents.compactMap {mapItem(item: $0)}

        let filtered = posts.filter { post in
            let tokenSet = Set(post.keywords)
            return tokens.allSatisfy { tokenSet.contains($0) }
        }
        
        return filtered.filter { !blockedUserIds.contains($0.authorId) }
    }
    
    func getPostsFromIds(ids: [String], blockedUserIds: [String] = []) async throws -> [PostModel] {
        guard !ids.isEmpty else { return [] }

        let pagedIds = Array(ids.prefix(100))
        
        let chunks = pagedIds.chunked(into: 10)
        var posts: [PostModel] = []

        for chunk in chunks {
            let snapshot = try await postsCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            for doc in snapshot.documents {
                posts.append(mapItem(item: doc))
            }
        }

        return posts.filter { !blockedUserIds.contains($0.authorId) }
    }

    func getTopUpsThisWeek(from cityIDs: [String], blockedUserIds: [String] = []) async throws -> ([PostModel], [Int]) {
        guard !cityIDs.isEmpty else { return ([], []) }
        let week = weekId()
        let chunks = cityIDs.chunked(into: 10)

        let stats: [WeeklyPostStat] = try await withThrowingTaskGroup(
            of: [WeeklyPostStat].self
        ) { group in

            for chunk in chunks {
                group.addTask {
                    let snap = try await Firestore.firestore()
                        .collection("WeeklyPostStats")
                        .whereField("week", isEqualTo: week)
                        .whereField("cityIds", arrayContainsAny: chunk)
                        .order(by: "upvotes", descending: true)
                        .limit(to: 5)
                        .getDocuments()

                    return snap.documents.compactMap {
                        WeeklyPostStat(doc: $0)
                    }
                }
            }

            var combined: [WeeklyPostStat] = []

            for try await result in group {
                combined.append(contentsOf: result)
            }

            return combined
        }

        let top5 = stats
            .reduce(into: [String: WeeklyPostStat]()) { dict, stat in
                dict[stat.postId] = max(dict[stat.postId] ?? stat, stat)
            }
            .values
            .sorted { $0.upvotes > $1.upvotes }
            .prefix(5)
        
        let postIds = top5
            .filter { $0.upvotes > 0 }
            .map { $0.postId }
        let upvotesById = Dictionary(uniqueKeysWithValues: top5.map { ($0.postId, $0.upvotes) })
        let posts = try await getPostsFromIds(ids: postIds, blockedUserIds: blockedUserIds)
        let filteredUps = posts.compactMap { upvotesById[$0.id] }
        return (posts, filteredUps)
    }

    
    func getTopUpsAllTime(from cityIDs: [String], blockedUserIds: [String] = []) async throws -> [PostModel] {
        guard !cityIDs.isEmpty else { return [] }
        let chunks = cityIDs.chunked(into: 10)

        let posts: [PostModel] = try await withThrowingTaskGroup(
            of: [PostModel].self
        ) { group in

            for chunk in chunks {
                group.addTask {
                    let snap = try await Firestore.firestore().collection("Posts")
                        .whereField("cityIds", arrayContainsAny: chunk)
                        .whereField("isHidden", isEqualTo: false)
                        .order(by: "upvotes", descending: true)
                        .limit(to: 5)
                        .getDocuments()

                    return snap.documents.map { self.mapItem(item: $0) }
                }
            }

            var combined: [PostModel] = []
            for try await result in group {
                combined.append(contentsOf: result)
            }
            return combined
        }

        let deduped = Dictionary(
            posts.map { ($0.id, $0) },
            uniquingKeysWith: { a, b in
                a.upvotes >= b.upvotes ? a : b
            }
        )

        let result = deduped.values
            .filter { $0.upvotes > 0 }
            .sorted { $0.upvotes > $1.upvotes }
            .prefix(5)
            .map { $0 }
        return result.filter { !blockedUserIds.contains($0.authorId) }
    }

  
    func getTopDownsAllTime(from cityIDs: [String], blockedUserIds: [String] = []) async throws -> [PostModel] {
        guard !cityIDs.isEmpty else { return [] }
        let chunks = cityIDs.chunked(into: 10)

        let posts: [PostModel] = try await withThrowingTaskGroup(
            of: [PostModel].self
        ) { group in

            for chunk in chunks {
                group.addTask {
                    let snap = try await Firestore.firestore().collection("Posts")
                        .whereField("cityIds", arrayContainsAny: chunk)
                        .whereField("isHidden", isEqualTo: false)
                        .order(by: "downvotes", descending: true)
                        .limit(to: 5)
                        .getDocuments()

                    return snap.documents.map { self.mapItem(item: $0) }
                }
            }

            var combined: [PostModel] = []
            for try await result in group {
                combined.append(contentsOf: result)
            }
            return combined
        }

        let deduped = Dictionary(
            posts.map { ($0.id, $0) },
            uniquingKeysWith: { a, b in
                a.downvotes >= b.downvotes ? a : b
            }
        )

        let result = deduped.values
            .filter { $0.downvotes > 0 }
            .sorted { $0.downvotes > $1.downvotes }
            .prefix(5)
            .map { $0 }
        return result.filter { !blockedUserIds.contains($0.authorId) }
    }

    
    func getUpvotedPostsFromCoreData(cursor: Date?, blockedUserIds: [String] = []) async throws -> ([PostModel], Date?) {
        let votedposts = CoreDataManager.shared.fetchUpvotedPostIds(pageSize: 10, cursor: cursor)
        print("Voted posts: ", votedposts)
        let nextCursor = votedposts.1
        let posts = try await getPostsFromIds(ids: votedposts.0)
        return (posts.filter { !blockedUserIds.contains($0.authorId) }, nextCursor)
    }
    
    func incrementReports(postId: String) async throws {
        try await postsCollection.document(postId).updateData(["reportCount": FieldValue.increment(Int64(1))])
    }
    
    func updateExpiry(postId: String) async throws {
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
        try await postsCollection.document(postId).updateData(["expiresAt": Timestamp(date: threeMonthsFromNow)])
    }
        
    private func mapItem(
        id: String,
        data: [String: Any]
    ) -> PostModel {

        let text = data["text"] as? String ?? "Untitled"
        let name = data["name"] as? String ?? "Anonymous"
        let imageUrl = data["imageUrl"] as? String ?? ""

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
            createdAt = Timestamp(date: Date())
        }

        let authorId = data["authorId"] as? String ?? ""
        let authorName = data["authorName"] as? String ?? ""
        let authorPicUrl = data["authorPicUrl"] as? String ?? ""

        let keywords = data["keywords"] as? [String] ?? []
        let tags = data["tags"] as? [String] ?? []
        let cityIds = data["cityIds"] as? [String] ?? []

        let upvotes = data["upvotes"] as? Int ?? 0
        let downvotes = data["downvotes"] as? Int ?? 0

        return PostModel(
            id: id,
            text: text,
            name: name,
            imageUrl: imageUrl,
            createdAt: createdAt,
            authorId: authorId,
            authorName: authorName,
            authorPicUrl: authorPicUrl,
            height: 260,
            cityIds: cityIds,
            tags: tags,
            keywords: keywords,
            upvotes: upvotes,
            downvotes: downvotes
        )
    }
    
    func decodePosts(from result: Any) -> [PostModel] {
        guard
            let dict = result as? [String: Any],
            let rawPosts = dict["posts"] as? [[String: Any]]
        else {
            return []
        }

        return rawPosts.compactMap { postDict in
            guard let id = postDict["id"] as? String else { return nil }
            return mapItem(id: id, data: postDict)
        }
    }


    func mapItem(item: DocumentSnapshot) -> PostModel {
        let id = item["id"] as? String ?? ""
        let text = item["text"] as? String ?? "Untitled"
        let name = item["name"] as? String ?? "Anonymous"
        let imageUrl = item["imageUrl"] as? String ?? ""
        let createdAt = item["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let authorId = item["authorId"] as? String ?? ""
        let authorName = item["authorName"] as? String ?? ""
        let authorPicUrl = item["authorPicUrl"] as? String ?? ""
        let keywords = item["keywords"] as? [String] ?? []
        let tags = item["tags"] as? [String] ?? []
        let cityIds = item["cityIds"] as? [String] ?? []
        let upvotes = item["upvotes"] as? Int ?? 0
        let downvotes = item["downvotes"] as? Int ?? 0
        
        return PostModel(id: id, text: text , name: name, imageUrl: imageUrl, createdAt: createdAt, authorId: authorId, authorName: authorName, authorPicUrl: authorPicUrl, height: 260, cityIds: cityIds, tags: tags, keywords: keywords, upvotes: upvotes, downvotes: downvotes)
    }
    
    func generateKeywords(authorName: String, subjectName: String, captionPrefix: String, tags: [String], cities: [String]) -> [String] {
        var inputs = [authorName, subjectName, String(captionPrefix.prefix(10))]
        
        inputs.append(contentsOf: tags)
        
        inputs.append(contentsOf: cities)
        
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
    
    func decodeCursor(from result: Any) -> FeedCursor? {
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
            let postId = cursor["postId"] as? String,
            let createdAtSeconds = cursor["createdAtSeconds"] as? TimeInterval
        else {
            print("Cursor malformed:", rawCursor)
            return nil
        }

        return FeedCursor(
            createdAtSeconds: createdAtSeconds,
            postId: postId
        )
    }



    let mockPosts: [PostModel] = [
        PostModel(
            id: "1245",
            text: "Exploring SwiftUI",
            name: "Alice",
            imageUrl: "Moose",
            createdAt: Timestamp(date: Date()),
            authorId: "Caden",
            authorName: "Caden1",
            authorPicUrl: "ProfPic1",
            height: 20,
            cityIds: ["NYC001"],
            tags: [],
            keywords: ["SwiftUI", "iOS", "Design"],
            upvotes: 0,
            downvotes: 0
        ),
        PostModel(
            id: "13255",
            text: "Firebase Tricks",
            name: "Bob",
            imageUrl: "Moose",
            createdAt: Timestamp(date: Date().addingTimeInterval(-1000)),
            authorId: "Caden",
            authorName: "Caden1",
            authorPicUrl: "ProfPic1",
            height: 120,
            cityIds: ["SF002", "LA003"],
            tags: [],
            keywords: ["Firebase", "Firestore", "Backend"],
            upvotes: 0,
            downvotes: 0
        )
    ]

    
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
    
    func generatePrefixes(
        from text: String,
        minLength: Int = 3,
        maxLength: Int = 15
    ) -> [String] {
        let normalized = text.normalizedForIndexing()
        let chars = Array(normalized)

        guard chars.count >= minLength else { return [] }

        return (minLength...min(chars.count, maxLength)).map {
            String(chars.prefix($0))
        }
    }
}
