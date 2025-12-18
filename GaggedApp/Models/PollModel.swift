//
//  PollModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/17/25.
//
import Foundation
import FirebaseFirestore

struct PollModel: Identifiable {
    let id: String
    let authorId: String
    let title: String
    let context: String
    let postId: String
    let optionsCount: Int
    let totalVotes: Int
    let createdAt: Timestamp
    let cityId: String
    let keywords: [String]
}

struct PollOption: Identifiable {
    var id: String
    var text: String
    var voteCount: Int
    var index: Int
}
