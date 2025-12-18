//
//  UserModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/11/25.
//

import Foundation
import FirebaseFirestore

struct UserModel: Identifiable {
    let id: String
    let username: String
    let garma: Int
    let imageAddress: String
    let createdAt: Timestamp
    let keywords: [String]
    
//    init(id: String, name: String, state: String, country: String, keywords: [String]) {
//        self.id = id
//        self.name = name
//        self.state = state
//        self.country = country
//        self.keywords = keywords
//    }
}
