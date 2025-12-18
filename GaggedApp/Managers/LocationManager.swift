//
//  LocationManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/18/25.
//


import Foundation
import SwiftUI
import CoreLocation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
   
   // FUNCTIONALLY A VIEW MODEL
    
    @AppStorage("lastCityIds") var lastCityIds = "[]"
    @AppStorage("cityChoiceId") var cityChoiceId: String = ""
    
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    @Published var selectedCity: City?
    @Published var citiesInRange: [String] = []
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var justGetLat: Bool = false
    
    let cityManager = CityManager.shared
    
    private var locationContinuation: CheckedContinuation<Void, Never>?
    
    private var lastGeocodedLocation: CLLocation?
    
    private let manager = CLLocationManager()
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocation() async {
        cityChoiceId = ""
        await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        }
    }
    
    func requestLocationIfNeeded(execute: Bool) async {
        guard execute else { return }
        guard cityChoiceId == "" else {
            if let selectedCity = cityManager.getCity(id: cityChoiceId) {
                setLocation(selectedCity)
            }
            justGetLat = true
            await withCheckedContinuation { continuation in
                self.locationContinuation = continuation
                manager.requestWhenInUseAuthorization()
                manager.startUpdatingLocation()
            }
            return
        }

    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func setLocation(_ city: City) -> [String]{
        
        self.citiesInRange = cityManager.getNearbyCities(
            userLat: city.lat,
            userLng: city.lng
        )

        let recentCities = decodeList(from: lastCityIds)

        // Get closest city (full model)
        guard
            let closestCityID = citiesInRange.first,
            let closestCity = cityManager.getCities(ids: [closestCityID]).first
        else { return citiesInRange }

        // If it's already selected, nothing to do
        guard closestCity.id != selectedCity?.id else { return citiesInRange }

        // If there *was* a previous selected city...
        if let prev = selectedCity?.id, !prev.isEmpty {

            // ...and it was NOT already in recentCities
            if !recentCities.contains(prev) {
                prependString(prev, to: &lastCityIds)
                
                // keep only 3 items
                if recentCities.count > 2 {
                    removeLastString(from: &lastCityIds)
                }
            }
        }

        // Update selected city
        selectedCity = closestCity
        cityChoiceId = closestCity.id
        
        return citiesInRange
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        defer {
            locationContinuation?.resume()
            locationContinuation = nil
            manager.stopUpdatingLocation()
        }
        
        guard let location = locations.last else { return }
        
        userLatitude = location.coordinate.latitude
        userLongitude = location.coordinate.longitude
        
        guard cityChoiceId == "" else {return}
        
        guard justGetLat == false else {
            justGetLat = false
            return
        }
        // Get all cities near the user
        self.citiesInRange = cityManager.getNearbyCities(
            userLat: location.coordinate.latitude,
            userLng: location.coordinate.longitude
        )
        
        let recentCities = decodeList(from: lastCityIds)

        // Get closest city (full model)
        guard
            let closestCityID = citiesInRange.first,
            let closestCity = cityManager.getCities(ids: [closestCityID]).first
        else { return }

        // If it's already selected, nothing to do
        guard closestCity.id != selectedCity?.id else { return }

        // If there *was* a previous selected city...
        if let prev = selectedCity?.id, !prev.isEmpty {

            // ...and it was NOT already in recentCities
            if !recentCities.contains(prev) {
                prependString(prev, to: &lastCityIds)
                
                // keep only 3 items
                if recentCities.count > 2 {
                    removeLastString(from: &lastCityIds)
                }
            }
        }

        // Update selected city
        selectedCity = closestCity
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
    
    func prependString(_ value: String, to json: inout String) {
        var list = decodeList(from: json)
        list.insert(value, at: 0)
        json = encodeList(list)
    }

    // Remove the **last** string in the list
    func removeLastString(from json: inout String) {
        var list = decodeList(from: json)
        guard !list.isEmpty else { return }
        list.removeLast()
        json = encodeList(list)
    }
    
    func decodeList(from json: String) -> [String] {
        let data = Data(json.utf8)
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    // Encode [String] → JSON
    func encodeList(_ list: [String]) -> String {
        let data = (try? JSONEncoder().encode(list)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}
