//
//  EventModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/23/25.
//

import Foundation
import FirebaseFirestore

struct EventModel: Identifiable, Codable, Hashable {
    var id: String
    let name: String
    let locationDetails: String
    let date: Date
    var rsvps: Int
    var imageUrl: String
    let description: String
    let authorId: String
    let authorName: String
    let cityId: String
    let keywords: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: EventModel, rhs: EventModel) -> Bool {
        lhs.id == rhs.id
    }
}
