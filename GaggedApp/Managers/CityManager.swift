//
//  CityManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/20/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class CityManager {
    static let shared = CityManager()
    
    private var citiesCollection: CollectionReference {
        Firestore.firestore().collection("Cities")
    }
    
    func getAllCities() async throws -> [CityModel] {
        var cities: [CityModel] = []
        
        do {
            let querySnapshot = try await citiesCollection.limit(to: 10).getDocuments()
            for document in querySnapshot.documents {
                let newitem = mapCity(item: document)
                cities.append(newitem)
            }
        }
        
        return cities
    }
  
    func getCitiesFromSearch(keyword: String) async throws -> [CityModel] {
        
        var cities: [CityModel] = []
        var newkeyword = keyword
        
        if keyword.contains(" ") {
            newkeyword = newkeyword.replacingOccurrences(of: " ", with: "")
        }
        
        do {
            let querySnapshot = try await citiesCollection.whereField("keywords", arrayContains: keyword.lowercased()).limit(to: 30).getDocuments()
              for document in querySnapshot.documents {
                  let newitem = mapCity(item: document)
                  cities.append(newitem)
              }
        } catch {
          print("Error getting documents: \(error)")
        }
        
        return cities
    }
    
    func mapCity(item: QueryDocumentSnapshot) -> CityModel {
        
        let id = item["id"] as? String ?? UUID().uuidString
        let name = item["name"] as? String ?? "Unknown City"
        let state = item["state"] as? String ?? "Unknown State"
        let country = item["country"] as? String ?? "Unknown Country"
        let keywords = item["keywords"] as? [String] ?? []
        
        return CityModel(id: id, name: name, state: state, country: country, keywords: keywords)
    }
    
}
