//
//  PostManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/3/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class FirebasePostManager {
    
    static let shared = FirebasePostManager()
    
    private var postsCollection: CollectionReference {
        Firestore.firestore().collection("Posts")
    }
    
    func uploadPost(post: PostModel) async throws {
        
        let postRef = postsCollection.document()
        let postId = postRef.documentID
        
        try await postRef.setData([
            "id": postId,
            "text": post.text,
            "imageUrl": post.imageUrl,
            "authorId": post.authorId,
            "name" : post.name,
            "createdAt" : post.createdAt,
            "cityIds" : post.cityIds,
            "keywords" : generateKeywords(title: post.text, name: post.name),
            "upvotes" : post.upvotes,
            "downvotes" : post.downvotes
        ])
    }
    
    func deletePost(postId: String) async throws {
        let postRef = postsCollection.document(postId)
        try await postRef.delete()
    }
    
    func getPosts(from cityIDs: [String]) async throws -> [PostModel] {
        
        // Break into batches of 10 per Firestore rule
        let batches = cityIDs.chunked(into: 10)
        
        var allPosts: [PostModel] = []
        var seen: Set<String> = []   // Avoid duplicate posts
        
        for batch in batches {
            let query = postsCollection
                .whereField("cityIds", arrayContainsAny: batch)
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
        
        return allPosts
    }

    func getPost(id: String) async throws -> PostModel {
        let doc = try await postsCollection.document(id).getDocument()
        return mapItem(item: doc)
    }
    
    func getUserPosts(uid: String) async throws -> [PostModel] {
        
        var posts: [PostModel] = []
        
        let query: Query = postsCollection.whereField("authorId", isEqualTo: uid).order(by: "createdAt", descending: true).limit(to: 20)
        let newDocs = try await query.getDocuments()
        
        for i in newDocs.documents {
            var post = await mapItem(item: i)
            posts.append(post)
        }
        
        return posts
        
    }
    
    func upvotePost(postId: String) async throws {
        try await postsCollection.document(postId).updateData(["upvotes": FieldValue.increment(Int64(1))])
    }
    
    func removeUpvote(postId: String) async throws {
        try await postsCollection.document(postId).updateData(["upvotes": FieldValue.increment(Int64(-1))])
    }
    
    func downvotePost(postId: String) async throws {
        try await postsCollection.document(postId).updateData(["downvotes": FieldValue.increment(Int64(1))])
    }
    
    func removeDownvote(postId: String) async throws {
        try await postsCollection.document(postId).updateData(["downvotes": FieldValue.increment(Int64(-1))])
    }
    
    func getAllPostsNearby(cities: [String]) async throws -> [PostModel] {
        var results: [PostModel] = []
        var seen: Set<String> = []

        let chunks = cities.chunked(into: 10)

        for chunk in chunks {
            let query = postsCollection
                .whereField("cityIds", arrayContainsAny: chunk)

            let snapshot = try await query.getDocuments()
            for doc in snapshot.documents {
                let post = mapItem(item: doc)
                if seen.insert(post.id).inserted {
                    results.append(post)
                }
            }
        }
        return results
    }
    
    func getPostsFromSearch(keyword: String, allPostsNearby: [PostModel]) async throws -> [PostModel] {

        return allPostsNearby.filter { post in
            let lower = keyword.lowercased()
            
            // 1. Match post name
            if post.name.lowercased().contains(lower) { return true }
            
            // 3. Match city names
            let cities = CityManager.shared.getCities(ids: post.cityIds)
            if cities.contains(where: { $0.city.lowercased().contains(lower) }) {
                return true
            }
            
            return false
        }
    }
    
    func getPostsFromIds(ids: [String]) async throws -> [PostModel] {
        var posts: [PostModel] = []
        for id in ids {
            let doc = try await postsCollection.document(id).getDocument()
            let newitem = mapItem(item: doc)
            posts.append(newitem)
        }
        return posts
    }

    func getTopUpsThisWeek(from cityIDs: [String]) async throws -> [PostModel] {
        let week = weekId()
        
        print("IN manager func")
        
        //        let snapshot = try await Firestore.firestore()
        //            .collection("WeeklyPostStats")
        //            .whereField("week", isEqualTo: week)
        //            .whereField("cityIds", arrayContainsAny: Array(cityIDs.prefix(10)))
        //            .order(by: "upvotes", descending: true)
        //            .limit(to: 5)
        //            .getDocuments()
        //
        //        let postIds = snapshot.documents.map { $0["postId"] as! String }
        
        let chunks = cityIDs.chunked(into: 10)
        
        var stats: [WeeklyPostStat] = []
        
        for chunk in chunks {
            let snap = try await Firestore.firestore()
                .collection("WeeklyPostStats")
                .whereField("week", isEqualTo: week)
                .whereField("cityIds", arrayContainsAny: chunk)
                .order(by: "upvotes", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            stats.append(contentsOf: snap.documents.compactMap { WeeklyPostStat(doc: $0) })
        }
        
        let top5 = stats
            .reduce(into: [String: WeeklyPostStat]()) { dict, stat in
                dict[stat.postId] = max(dict[stat.postId] ?? stat, stat)
            }
            .values
            .sorted { $0.upvotes > $1.upvotes }
            .prefix(5)
        
        let postIds = top5.filter({$0.upvotes > 0}).compactMap({$0.postId})
        
        print("GOT WEEKLY UPS", postIds)

        return try await getPostsFromIds(ids: postIds)
    }
    
    func getTopUpsAllTime(from cityIDs: [String]) async throws -> [PostModel] {
        let chunks = cityIDs.chunked(into: 10)

        var postMap: [String: PostModel] = [:]

        for chunk in chunks {
            let snap = try await postsCollection
                .whereField("cityIds", arrayContainsAny: chunk)
                .order(by: "upvotes", descending: true)
                .limit(to: 20) // IMPORTANT: over-fetch
                .getDocuments()

            for doc in snap.documents {
                let post = mapItem(item: doc)

                // Deduplicate + keep highest-upvote version
                if let existing = postMap[post.id] {
                    if post.upvotes > existing.upvotes {
                        postMap[post.id] = post
                    }
                } else {
                    postMap[post.id] = post
                }
            }
        }

        return postMap.values.filter({$0.upvotes > 0})
            .sorted { $0.upvotes > $1.upvotes }
            .prefix(5)
            .map { $0 }
    }

  
    func getTopDownsAllTime(from cityIDs: [String]) async throws -> [PostModel] {
        let chunks = cityIDs.chunked(into: 10)

        var postMap: [String: PostModel] = [:]

        for chunk in chunks {
            let snap = try await postsCollection
                .whereField("cityIds", arrayContainsAny: chunk)
                .order(by: "downvotes", descending: true)
                .limit(to: 20) // IMPORTANT: over-fetch
                .getDocuments()

            for doc in snap.documents {
                let post = mapItem(item: doc)

                // Deduplicate + keep highest-upvote version
                if let existing = postMap[post.id] {
                    if post.upvotes > existing.upvotes {
                        postMap[post.id] = post
                    }
                } else {
                    postMap[post.id] = post
                }
            }
        }

        return postMap.values.filter({$0.downvotes > 0})
            .sorted { $0.upvotes > $1.upvotes }
            .prefix(5)
            .map { $0 }
    }
    
    func getUpvotedPostFromCoreData() async throws -> [PostModel] {
        let votedposts = CoreDataManager.shared.getUpvotedPosts()
        let posts = try await getPostsFromIds(ids: votedposts.compactMap({$0.id}))
        return posts
    }
        

    private func mapItem(item: DocumentSnapshot) -> PostModel {
        let id = item["id"] as? String ?? ""
        let text = item["text"] as? String ?? "Untitled"
        let name = item["name"] as? String ?? "Anonymous"
        let imageUrl = item["imageUrl"] as? String ?? ""
        let createdAt = item["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let authorId = item["authorId"] as? String ?? ""
        let keywords = item["keywords"] as? [String] ?? []
        let cityIds = item["cityIds"] as? [String] ?? []
        let citiesData = item["cities"] as? [[String: Any]] ?? []
        let upvotes = item["upvotes"] as? Int ?? 0
        let downvotes = item["downvotes"] as? Int ?? 0

        print("mapping doc", id)
        
        return PostModel(id: id, text: text , name: name, imageUrl: imageUrl, createdAt: createdAt, authorId: authorId, height: 180, cityIds: cityIds, keywords: keywords, upvotes: upvotes, downvotes: downvotes)
    }
    
    func generateKeywords(title: String, name: String) -> [String] {
        let inputs = [String(title.prefix(10)), name]
        
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
    
    let mockPosts: [PostModel] = [
        PostModel(
            id: "1245",
            text: "Exploring SwiftUI",
            name: "Alice",
            imageUrl: "Moose",
            createdAt: Timestamp(date: Date()),
            authorId: "Caden",
            height: 20,
            cityIds: ["NYC001"],
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
            height: 120,
            cityIds: ["SF002", "LA003"],
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
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
