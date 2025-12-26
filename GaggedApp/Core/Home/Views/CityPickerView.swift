//
//  CityPickerView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/2/25.
//

import SwiftUI

struct CityPickerView: View {
    
    @AppStorage("lastCityIds") var lastCityIds = "[]"
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    let dissmissable: Bool
    
    @Binding var showCityPickerView: Bool

    @State var recentIDs: [String] = []
    @State var recentCities: [City] = []
    
    let cityManager = CityManager.shared
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            ScrollView {
                VStack {
                    header
                        .padding(.bottom)
                    citiesSection
                }
                .padding()
            }
        }
        .onChange(of: lastCityIds) { newValue in
           recentIDs = decodeList(from: newValue)
           recentCities = cityManager.getCities(ids: recentIDs)
        }
        .onAppear {
            recentIDs = decodeList(from: lastCityIds)
            recentCities = cityManager.getCities(ids: recentIDs)
            homeViewModel.addSubscribers(recentCities)
            print(lastCityIds)
        }
    }
    
    var header: some View {
        HStack {
            if dissmissable {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .onTapGesture {
                        print("dissmiss")
                        showCityPickerView = false
                    }
            }
            HStack(spacing: 8) {

                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundStyle(.secondary)

                TextField("Search Cities", text: $homeViewModel.citySearchText)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Color.theme.lightGray
                    .opacity(0.2)
                    .cornerRadius(16)
            )
            .padding(.horizontal, 8)
        }
    }
    
    var citiesSection: some View {
        VStack(spacing: 12) {
            
            Text("Current City")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
                .padding(.horizontal)
            
            if let city = locationManager.selectedCity {
                cityRow(city: city, isRecent: false)
                    .background(
                        Color.theme.lightGray.opacity(0.15)
                            .cornerRadius(15)
                    )
            }
            else {
                HStack(spacing: 0) {

                    Text(locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted  ? "Change Location Permissions" : "Use Current Location")
                        .font(.body)
                        .foregroundStyle(Color.theme.lightBlue)
            
                    Spacer()
                    
                    Image(systemName: locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted  ? "gear" :"arrow.clockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(Color.theme.lightBlue)
                        .padding(8)
                }
                .padding(.horizontal)
                .frame(height: 55)
                .background(
                    Rectangle()
                        .fill(Color.theme.background.opacity(0.001))
                        .onTapGesture {
                            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                Task {
                                    try await locationManager.requestLocation()
                                }
                            }
                        }
                )
                .background(
                    Color.theme.lightGray.opacity(0.15)
                        .cornerRadius(15)
                )
            }

            // Title
            Text("Select New City")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 0) {

                // Recent Cities
                if homeViewModel.citySearchText == "" {
                    ForEach(recentCities.filter {$0.id != locationManager.selectedCity?.id}) { city in
                        cityRow(city: city, isRecent: true)
                            .onTapGesture {
                                cityTapped(city: city)
                            }
                        Divider()
                    }
                }

                // All Cities minus recent
                ForEach(homeViewModel.allCitiesList.filter{$0.id != locationManager.selectedCity?.id }) { city in
                    if recentIDs.contains(city.id) {
                        cityRow(city: city, isRecent: true)
                            .onTapGesture {
                                cityTapped(city: city)
                            }
                    }
                    else  {
                        cityRow(city: city, isRecent: false)
                            .onTapGesture {
                                cityTapped(city: city)
                            }
                    }
                    if city.id != homeViewModel.allCitiesList.last?.id { Divider() }
                }
            }
            .background(
                Color.theme.lightGray.opacity(0.15)
                    .cornerRadius(15)
            )
        }
    }
    
    func cityTapped(city: City) {
        // set user location to city chosen
        Task {
            homeViewModel.isLoading = true
            showCityPickerView = false
            let citiesInRange = locationManager.setLocation(city)
            try await homeViewModel.fetchMorePosts(cities: citiesInRange)
            homeViewModel.isLoading = false
        }
        // don't let it get reset
    }

    // MARK: - Reusable row (NO new functionality, just layout cleanup)
    private func cityRow(city: City, isRecent: Bool) -> some View {
        HStack(spacing: 0) {

            Text(city.city)
                .font(.body)

            Text(", \(city.state_id)")
                .font(.body)
                .italic()
            
            if let userLatitude = locationManager.userLatitude, let userLongitude = locationManager.userLongitude {
                Text(" \(String(getMileage(userLat: userLatitude, userLng: userLongitude, cityLat: city.lat, cityLng: city.lng)))m")
                    .font(.caption)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.top, 4)
                    .padding(.leading, 4)
            }

            if isRecent {
                Text(" Recent")
                    .font(.caption)
                    .foregroundStyle(Color.theme.darkBlue)
                    .italic()
                    .padding(.leading, 16)
            }

            Spacer()

            if city.city == locationManager.selectedCity?.city {
                Image(systemName: "checkmark")
                    .font(.body)
                    .foregroundStyle(Color.theme.darkBlue)
            }
        }
        .padding(.horizontal)
        .frame(height: 55)
        .background(
            Rectangle()
                .fill(Color.theme.background.opacity(0.001))
                .onTapGesture {
                    cityTapped(city: city)
                }
        )
    }
    
    func getMileage(userLat: Double, userLng: Double, cityLat: Double, cityLng: Double) -> Int {
        
        let earthRadiusKm = 6371.0
        
        // Convert degrees to radians
        let dLat = (userLat - cityLat) * .pi / 180
        let dLng = (userLng - cityLng) * .pi / 180
        
        let lat1 = cityLat * .pi / 180
        let lat2 = userLat * .pi / 180
        
        // Haversine formula
        let a = sin(dLat/2) * sin(dLat/2)
              + sin(dLng/2) * sin(dLng/2) * cos(lat1) * cos(lat2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return Int(earthRadiusKm * c)
    }
    
    func decodeList(from json: String) -> [String] {
        let data = Data(json.utf8)
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}
