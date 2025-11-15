//
//  City.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//

struct CityModel: Identifiable, Codable {
    let id: String
    let name: String
    let state: String
    let country: String
    let keywords: [String]
    
    init(id: String, name: String, state: String, country: String, keywords: [String]) {
        self.id = id
        self.name = name
        self.state = state
        self.country = country
        self.keywords = keywords
    }
}
