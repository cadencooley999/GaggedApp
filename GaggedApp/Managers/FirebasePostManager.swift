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
            "authorName" : post.authorName,
            "name" : post.name,
            "createdAt" : post.createdAt,
            "upvotes" : post.upvotes,
            "downvotes" : post.downvotes,
            "cityIds" : post.cityIds,
            "cities" : try post.cities.map { try Firestore.Encoder().encode($0) },
            "keywords" : generateKeywords(title: post.text, name: post.name, authorName: post.authorName),
            "upvotesThisWeek" : post.upvotesThisWeek,
            "lastUpvoted" : post.lastUpvoted
        ])
    }
    
    func deletePost(postId: String) async throws {
        let postRef = postsCollection.document(postId)
        try await postRef.delete()
    }
    
    func getPosts() async throws -> [PostModel] {
        
        var posts: [PostModel] = []
        
        let query: Query = postsCollection.limit(to: 20)
        let newDocs = try await query.getDocuments()
                                        
        for i in newDocs.documents {
              let post = await mapItem(item: i)
              posts.append(post)
          }
        
        return posts
    }
    
    func getPost(id: String) async throws -> PostModel {
        let doc = try await postsCollection.document(id).getDocument()
        return await mapItem(item: doc)
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
    
    func getPostsFromSearch(keyword: String) async throws -> [PostModel] {
        
        var posts: [PostModel] = []
        var newkeyword = keyword
        
        if keyword.contains(" ") {
            newkeyword = newkeyword.replacingOccurrences(of: " ", with: "")
        }
        
        do {
            let querySnapshot = try await postsCollection.whereField("keywords", arrayContains: keyword.lowercased()).limit(to: 30).getDocuments()
              for document in querySnapshot.documents {
                  let newitem = await mapItem(item: document)
                  posts.append(newitem)
              }
        } catch {
          print("Error getting documents: \(error)")
        }
        
        return posts
    }
    
    func getPostsFromIds(ids: [String]) async throws -> [PostModel] {
        var posts: [PostModel] = []
        for id in ids {
            let doc = try await postsCollection.document(id).getDocument()
            let newitem = await mapItem(item: doc)
            posts.append(newitem)
        }
        return posts
    }

    func getTopUpsThisWeek() async throws -> [PostModel] {
        var posts: [PostModel] = []
        
        // Use a fixed calendar + UTC timezone for consistency with Firestore
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // 🔥 force UTC

        let now = Date()
        
        // Compute Sunday 12:00 AM UTC
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let startOfWeek = calendar.date(from: components),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)
        else {
            throw NSError(domain: "DateError", code: 0)
        }
        
        // Convert to Firestore Timestamps
        let startTimestamp = Timestamp(date: startOfWeek)
        let endTimestamp = Timestamp(date: endOfWeek)
        
        print("Start of week (UTC): \(startOfWeek)")
        print("End of week (UTC): \(endOfWeek)")
        
        // ✅ Fixed field name and consistent range
        let query = postsCollection
            .whereField("lastUpvoted", isGreaterThanOrEqualTo: startTimestamp)
            .whereField("lastUpvoted", isLessThan: endTimestamp)
            .order(by: "upvotesThisWeek", descending: true)
            .limit(to: 5)
        
        let snapshot = try await query.getDocuments()
        
        for doc in snapshot.documents {
            var post = await mapItem(item: doc)
            post.height = 320
            posts.append(post)
            print("✅ Fetched post \(post.id)")
        }
        
        return posts
    }
    
    func getTopUpsAllTime() async throws -> [PostModel] {
        var posts: [PostModel] = []
        
        let query: Query = postsCollection.order(by: "upvotes", descending: true).limit(to: 5)
        let newDocs = try await query.getDocuments()
        
        for i in newDocs.documents {
            var post = await mapItem(item: i)
            post.height = 320
            posts.append(post)
        }
        
        return posts
    }
  
    func getTopDownsAllTime() async throws -> [PostModel] {
        var posts: [PostModel] = []
        
        let query: Query = postsCollection.order(by: "downvotes", descending: true).limit(to: 5)
        let newDocs = try await query.getDocuments()
        
        for i in newDocs.documents {
            var post = await mapItem(item: i)
            post.height = 320
            posts.append(post)
        }
        
        return posts
    }
        

    private func mapItem(item: DocumentSnapshot) async -> PostModel {
        let id = item["id"] as? String ?? ""
        let text = item["text"] as? String ?? "Untitled"
        let name = item["name"] as? String ?? "Anonymous"
        let imageUrl = item["imageUrl"] as? String ?? ""
        let createdAt = item["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let upvotes = item["upvotes"] as? Int ?? 0
        let upvotesThisWeek = item["upvotesThisWeek"] as? Int ?? 0
        let lastUpvoted = item["lastUpvoted"] as? Timestamp ?? nil
        let downvotes = item["downvotes"] as? Int ?? 0
        let authorId = item["authorId"] as? String ?? ""
        let authorName = item["authorName"] as? String ?? ""
        let keywords = item["keywords"] as? [String] ?? []
        let cityIds = item["cityIds"] as? [String] ?? []
        let citiesData = item["cities"] as? [[String: Any]] ?? []
        let cities: [CityLiteModel] = citiesData.compactMap { (dict) -> CityLiteModel? in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let state = dict["state"] as? String,
                  let country = dict["country"] as? String else {
                return nil
            }
            return CityLiteModel(id: id, name: name, state: state, country: country)
        }

        print("mapping doc", id)
        
        return PostModel(id: id, text: text , name: name, imageUrl: imageUrl, upvotes: upvotes, downvotes: downvotes, createdAt: createdAt, authorId: authorId, authorName: authorName, height: 180, cityIds: cityIds, cities: cities, keywords: keywords, upvotesThisWeek: upvotesThisWeek, lastUpvoted: lastUpvoted)
    }
    
    func upvotePost(post: PostModel) async throws {
        if !wasThisWeek(date: post.lastUpvoted) {
            try await postsCollection.document(post.id).updateData([
                "upvotes": FieldValue.increment(Int64(1)),
                "upvotesThisWeek": 1,
                "lastUpvoted" : Timestamp(date: Date())
            ])
        }
        else {
            try await postsCollection.document(post.id).updateData([
                "upvotes": FieldValue.increment(Int64(1)),
                "upvotesThisWeek": FieldValue.increment(Int64(1)),
                "lastUpvoted" : Timestamp(date: Date())
            ])
        }
    }
    
    func downvotePost(postId: String) async throws {
        try await postsCollection.document(postId).updateData([
            "downvotes": FieldValue.increment(Int64(1))
        ])
    }
    
    func generateKeywords(title: String, name: String, authorName: String) -> [String] {
        let inputs = [title, name, authorName]
        
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
    
    func wasThisWeek(date: Timestamp? ) -> Bool {
        
        guard let date = date else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let targetDate = date.dateValue()

        // Configure the calendar so weeks start on Sunday
        var adjustedCalendar = calendar
        adjustedCalendar.firstWeekday = 1 // 1 = Sunday

        // Get the start of the current week (Sunday 12am)
        guard let startOfWeek = adjustedCalendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return false
        }

        // End of the week = start + 7 days
        guard let endOfWeek = adjustedCalendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return false
        }

        // Check if targetDate falls between start and end of current week
        return (targetDate >= startOfWeek) && (targetDate < endOfWeek)
    }

    
    let mockPosts: [PostModel] = [
        PostModel(
            id: "1245",
            text: "Exploring SwiftUI",
            name: "Alice",
            imageUrl: "Moose",
            upvotes: 12,
            downvotes: 1,
            createdAt: Timestamp(date: Date()),
            authorId: "Caden", authorName: "Caden134", height: 120,
            cityIds: ["NYC001"],
            cities: [mockCities[0]],
            keywords: ["SwiftUI", "iOS", "Design"],
            upvotesThisWeek: 0,
            lastUpvoted: nil
        ),
        PostModel(
            id: "13255",
            text: "Firebase Tricks",
            name: "Bob",
            imageUrl: "Moose",
            upvotes: 20,
            downvotes: 2,
            createdAt: Timestamp(date: Date().addingTimeInterval(-1000)),
            authorId: "Caden",
            authorName: "Caden134",
            height: 120,
            cityIds: ["SF002", "LA003"],
            cities: [mockCities[1], mockCities[2]],
            keywords: ["Firebase", "Firestore", "Backend"],
            upvotesThisWeek: 0,
            lastUpvoted: nil
        )
    ]
    


}

extension FirebasePostManager {
    static let mockCities: [CityLiteModel] = [
        CityLiteModel(id: "NYC001", name: "New York", state: "New York", country: "USA"),
        CityLiteModel(id: "SF002", name: "San Francisco", state: "California", country: "USA"),
        CityLiteModel(id: "LA003", name: "Los Angeles", state: "California", country: "USA"),
        CityLiteModel(id: "SEA004", name: "Seattle", state: "Washington", country: "USA"),
        CityLiteModel(id: "DEN005", name: "Denver", state: "Colorado", country: "USA"),
        CityLiteModel(id: "CHI006", name: "Chicago", state: "Illinois", country: "USA"),
        CityLiteModel(id: "ATL007", name: "Atlanta", state: "Georgia", country: "USA"),
        CityLiteModel(id: "MIA008", name: "Miami", state: "Florida", country: "USA"),
        CityLiteModel(id: "DAL009", name: "Dallas", state: "Texas", country: "USA"),
        CityLiteModel(id: "BOS010", name: "Boston", state: "Massachusetts", country: "USA")
    ]


}
