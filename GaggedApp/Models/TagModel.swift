//
//  TagModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/2/26.
//

import FirebaseFirestore

struct TagModel {
    let id: String
    let category: String
    let title: String
    
    init(id: String, category: String, title: String) {
        self.id = id
        self.category = category
        self.title = title
    }
    
    init?(document: DocumentSnapshot) {
        let id = document.documentID
        guard let data = document.data(),
              let category = data["category"] as? String,
              let title = data["title"] as? String else {
            return nil
        }

        self.id = id
        self.category = category
        self.title = title
    }
}

struct TagCategory {
    let id: String
    let title: String
    let order: Int
    
    init(id: String, title: String, order: Int) {
        self.id = id
        self.title = title
        self.order = order
    }
    
    init?(document: DocumentSnapshot) {
        let id = document.documentID
        guard let data = document.data(),
              let title = data["name"] as? String,
              let order = data["order"] as? Int else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.order = order
    }
}
