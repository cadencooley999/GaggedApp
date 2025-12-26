//
//  LocationManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/18/25.
//


import Foundation
import SwiftUI
import CoreLocation

enum LocationError: Error {
    case permissionDenied
    case failed
}

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
    
    private var locationContinuation: CheckedContinuation<[String], Error>?

    private var lastGeocodedLocation: CLLocation?
    
    private let manager = CLLocationManager()
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocation() async throws -> [String] {
        cityChoiceId = ""

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        }
    }
    
    func requestLocationIfNeeded(execute: Bool) async throws -> [String] {
        guard execute else { return []}
        var cities: [String] = []
        guard cityChoiceId == "" else {
            if let selectedCity = cityManager.getCity(id: cityChoiceId) {
                 cities = setLocation(selectedCity)
            }
            justGetLat = true
            try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                manager.requestWhenInUseAuthorization()
                manager.startUpdatingLocation()
            }
            return cities
        }
        return []
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()

        case .denied, .restricted:
            locationContinuation?.resume(throwing: LocationError.permissionDenied)
            locationContinuation = nil

        default:
            break
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationContinuation?.resume(throwing: LocationError.failed)
        locationContinuation = nil
    }

    
    func setLocation(_ city: City) -> [String] {
        
        self.citiesInRange = cityManager.getNearbyCities(
            userLat: city.lat,
            userLng: city.lng
        )
        
        print("ran cities in range func")

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

        guard let location = locations.last else { return }

        userLatitude = location.coordinate.latitude
        userLongitude = location.coordinate.longitude

        // ─────────────────────────────
        // JUST GET LAT MODE
        // ─────────────────────────────
        if justGetLat {
            justGetLat = false

            locationContinuation?.resume(returning: citiesInRange)
            locationContinuation = nil
            manager.stopUpdatingLocation()
            return
        }

        // ─────────────────────────────
        // CITY ALREADY CHOSEN
        // ─────────────────────────────
        if cityChoiceId != "" {
            locationContinuation?.resume(returning: citiesInRange)
            locationContinuation = nil
            manager.stopUpdatingLocation()
            return
        }

        // ─────────────────────────────
        // NORMAL FLOW
        // ─────────────────────────────

        let rangeCities = cityManager.getNearbyCities(
            userLat: location.coordinate.latitude,
            userLng: location.coordinate.longitude
        )

        citiesInRange = rangeCities

        let recentCities = decodeList(from: lastCityIds)

        guard
            let closestCityID = citiesInRange.first,
            let closestCity = cityManager.getCities(ids: [closestCityID]).first
        else {
            locationContinuation?.resume(returning: citiesInRange)
            locationContinuation = nil
            manager.stopUpdatingLocation()
            return
        }

        if closestCity.id != selectedCity?.id {

            if let prev = selectedCity?.id, !prev.isEmpty,
               !recentCities.contains(prev) {

                prependString(prev, to: &lastCityIds)

                if recentCities.count > 2 {
                    removeLastString(from: &lastCityIds)
                }
            }

            selectedCity = closestCity
            cityChoiceId = closestCity.id
        }

        // ─────────────────────────────
        // FINAL RESUME (SUCCESS)
        // ─────────────────────────────
        locationContinuation?.resume(returning: citiesInRange)
        locationContinuation = nil
        manager.stopUpdatingLocation()
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
