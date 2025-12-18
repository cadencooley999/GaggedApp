//
//  CityManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/20/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import CoreLocation

class CityManager {
    static let shared = CityManager()
    
    var allCities: [City] = []

    init() {
        loadCities()
    }

    private func loadCities() {
        guard let url = Bundle.main.url(forResource: "us_cities_with_id", withExtension: "json") else {
            print("❌ cities.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([City].self, from: data)
            self.allCities = decoded
        } catch {
            print("❌ Failed to decode cities.json:", error)
        }
    }
    
    func getCity(id: String) -> City? {
        return allCities.first(where: { $0.id == id })
    }
    
    func getCities(ids: [String]) -> [City] {
        let idSet = Set(ids)
        return allCities.filter { idSet.contains($0.id)}
    }
    
    func getNearbyCities(userLat: Double, userLng: Double) -> [String] {
        let milesRadius = 30.0
        let radiusMeters = milesRadius * 1609.34
        
        let userLoc = CLLocation(latitude: userLat, longitude: userLng)
        
        // Filter AND sort by distance
        let sortedList = CityManager.shared.allCities
            .map { city -> (City, CLLocationDistance) in
                let cityLoc = CLLocation(latitude: city.lat, longitude: city.lng)
                let dist = userLoc.distance(from: cityLoc)
                return (city, dist)
            }
            .filter { $0.1 <= radiusMeters }
            .sorted { $0.1 < $1.1 }   // sort by distance
        
        return sortedList.map { $0.0.id }
    }
}
