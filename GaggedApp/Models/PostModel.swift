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
    let createdAt: Timestamp
    var height: CGFloat
    let authorId: String
    let authorName: String
    let authorPicUrl: String
    let cityIds: [String]
    var keywords: [String]
    var upvotes: Int
    var downvotes: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PostModel, rhs: PostModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, text: String, name: String, imageUrl: String, createdAt: Timestamp, authorId: String, authorName: String, authorPicUrl: String, height: CGFloat, cityIds: [String], keywords: [String], upvotes: Int, downvotes: Int) {
        self.id = id
        self.text = text
        self.name = name
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.height = height
        self.authorId = authorId
        self.authorName = authorName
        self.authorPicUrl = authorPicUrl
        self.cityIds = cityIds
        self.keywords = keywords
        self.upvotes = upvotes
        self.downvotes = downvotes
    }
}
