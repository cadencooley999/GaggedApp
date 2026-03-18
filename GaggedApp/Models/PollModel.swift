//
//  PollModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/17/25.
//
import Foundation
import FirebaseFirestore

struct PollModel: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let authorPicUrl: String
    let title: String
    let context: String
    let linkedPostId: String
    let linkedPostName: String
    let optionsCount: Int
    var totalVotes: Int
    let createdAt: Timestamp
    let cityId: String
    let keywords: [String]
}

struct PollOption: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var voteCount: Int
    var index: Int
}

struct PollWithOptions: Equatable, Identifiable, Codable {
    let id: String
    var poll: PollModel
    var options: [PollOption]
    
    static func == (lhs: PollWithOptions, rhs: PollWithOptions) -> Bool {
        return lhs.compositeID == rhs.compositeID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var compositeID: String {
        "\(id)-\(options.count)-\(options.map(\.voteCount))"
    }
}
