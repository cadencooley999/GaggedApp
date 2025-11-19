//
//  LocationManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/18/25.
//


import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    @Published var cityName: String?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    private var lastGeocodedLocation: CLLocation?
    
    private let manager = CLLocationManager()
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        
        print(self.authorizationStatus)
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLatitude = location.coordinate.latitude
        userLongitude = location.coordinate.longitude
        
        print("CALLING LOCMANAGER")
        
        // Reverse geocode to get ci
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                let newCity = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown"
                if newCity != self.cityName {
                    self.cityName = newCity // @AppStorage if you use it
                }
            }
        }
        
        manager.stopUpdatingLocation() // stop after first fetch
    }
    
    func checkAuthStatus() {
        print("AUTH STATUS:", CLLocationManager.authorizationStatus().rawValue)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
