//
//  Post.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import Foundation
import FirebaseFirestore

struct PostModel: Identifiable, Codable, Hashable {
    var id: String
    let text: String
    var name: String
    var imageUrl: String
    var upvotes: Int
    var downvotes: Int
    let createdAt: Timestamp
    var height: CGFloat
    let authorId: String
    let authorName: String
    let cities: [CityLiteModel]
    let cityIds: [String]
    var keywords: [String]
    var upvotesThisWeek: Int
    var lastUpvoted: Timestamp?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PostModel, rhs: PostModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, text: String, name: String, imageUrl: String, upvotes: Int, downvotes: Int, createdAt: Timestamp, authorId: String, authorName: String, height: CGFloat, cityIds: [String], cities: [CityLiteModel], keywords: [String], upvotesThisWeek: Int, lastUpvoted: Timestamp?) {
        self.id = id
        self.text = text
        self.name = name
        self.imageUrl = imageUrl
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.createdAt = createdAt
        self.height = height
        self.authorId = authorId
        self.authorName = authorName
        self.cities = cities
        self.cityIds = cityIds
        self.keywords = keywords
        self.upvotesThisWeek = upvotesThisWeek
        self.lastUpvoted = lastUpvoted
    }
    
}
