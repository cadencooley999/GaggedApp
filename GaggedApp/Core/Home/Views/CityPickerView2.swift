//
//  CityPickerView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/2/25.
//

import SwiftUI

struct CityPickerView2: View {
    
    @AppStorage("lastCityIds") var lastCityIds = "[]"
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var leaderViewModel: LeaderViewModel
    @EnvironmentObject var windowSize: WindowSize
    
    let dissmissable: Bool
    
    @Binding var showCityPickerView: Bool
    @Binding var selectedTab: TabBarItem

    @FocusState var isFocused: Bool
    @State var showxmark: Bool = false
    
    @State var recentIDs: [String] = []
    @State var recentCities: [City] = []
    
    let cityManager = CityManager.shared
    
    var body: some View {
        ZStack {
            Background()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    citiesSection
                }
                .padding(.top, 80)
                .padding(.bottom, 100)
            }
            .onScrollPhaseChange({ oldPhase, newPhase in
                if newPhase == .interacting {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFocused = false
                    }
                }
            })
            
            VStack {
                ZStack {
                    VStack {
                        BackgroundHelper.shared.appleHeaderBlur.frame(height: 88)
                        Spacer()
                    }
                    VStack {
                        header
                            .frame(height: 55)
                        Spacer()
                    }
                }
                Spacer()
                ZStack {
                    VStack { Spacer(); BackgroundHelper.shared.appleFooterBlur.frame(height: 55) }
                    VStack { Spacer(); footer }
                }
            }
        }
        .onChange(of: lastCityIds) { newValue in
            recentIDs = decodeList(from: newValue)
            recentCities = cityManager.getCities(ids: recentIDs)
        }
        .onAppear {
            recentIDs = decodeList(from: lastCityIds)
            recentCities = cityManager.getCities(ids: recentIDs)
            homeViewModel.bindCitySearch(recentCities: recentCities)
            print(lastCityIds)
        }
        .onChange(of: isFocused) {
            showxmark = isFocused
        }
    }
    
    var header: some View {
        HStack {
            if dissmissable {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCityPickerView = false
                        }
                    }
            }
            Spacer()
            Text("City Selection")
                .font(.headline)
            Spacer()
            Circle().frame(width: 44, height: 44).opacity(0)
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 6)
    }
    
    var footer: some View {
        GlassEffectContainer {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.theme.darkBlue)
                    TextField("Search Cities", text: $homeViewModel.citySearchText)
                        .font(.body)
                        .focused($isFocused)
                }
                .padding(14)
                .contentShape(Rectangle())
                .glassEffect()

                if showxmark {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .padding(8)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .glassEffectTransition(.materialize)
                        .onTapGesture { isFocused = false }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.3), value: showxmark)
    }
    
    var citiesSection: some View {
        VStack(spacing: 16) {
            // Current City
            Text("Current City")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.gray)
                .padding(.horizontal)

            VStack(spacing: 0) {
                if let city = locationManager.selectedCity {
                    cityRow(city: city, isRecent: false)
                } else {
                    HStack(spacing: 0) {
                        Text(locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted  ? "Change Location Permissions" : "Use Current Location")
                            .font(.body)
                            .foregroundStyle(Color.theme.darkBlue)
                        Spacer()
                        Image(systemName: locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted  ? "gear" :"arrow.clockwise")
                            .font(.subheadline.bold())
                            .foregroundColor(Color.theme.darkBlue)
                            .padding(8)
                    }
                    .padding(.horizontal)
                    .frame(height: 55)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                            // Mark that we're heading to Settings so we don't update on return
                            locationManager.clearLocationData()
                            locationManager.returningFromSettings = true
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } else {
                            Task {
                                // Request current location; this will prompt if needed and then deliver updates
                                let cities = try await locationManager.requestLocation()
                                if cities.isEmpty {
                                    // Fallback to manager's citiesInRange if continuation returned empty
                                    try await resetNecessary(citiesInRange: locationManager.citiesInRange)
                                } else {
                                    try await resetNecessary(citiesInRange: cities)
                                }
                            }
                        }
                    }
                    
                }
            }
            .background {
                Rectangle().fill(.thinMaterial).cornerRadius(30)
            }
            .padding(.horizontal)

            // Select New City
            Text("Select New City")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.gray)
                .padding(.horizontal)

            LazyVStack(spacing: 0) {
                // Recent Cities first if search empty
                if homeViewModel.citySearchText == "" {
                    ForEach(recentCities.filter { $0.id != locationManager.selectedCity?.id }) { city in
                        cityRow(city: city, isRecent: true)
                            .onTapGesture { cityTapped(city: city) }
                        Divider().padding(.leading, 16)
                    }
                }

                // All Cities minus current
                ForEach(homeViewModel.allCitiesList.filter { $0.id != locationManager.selectedCity?.id }) { city in
                    if recentIDs.contains(city.id) {
                        cityRow(city: city, isRecent: true)
                            .onTapGesture { cityTapped(city: city) }
                    } else {
                        cityRow(city: city, isRecent: false)
                            .onTapGesture { cityTapped(city: city) }
                    }
                    if city.id != homeViewModel.allCitiesList.last?.id { Divider().padding(.leading, 16) }
                }
            }
            .background {
                Rectangle().fill(.thinMaterial).cornerRadius(30)
            }
            .padding(.horizontal)
        }
    }
    
    func cityTapped(city: City) {
        // set user location to city chosen
        Task {
            homeViewModel.isLoading = true
            print("setting range")
            let citiesInRange = locationManager.setLocation(city)
            try await resetNecessary(citiesInRange: citiesInRange)
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
    
    func resetNecessary(citiesInRange: [String]) async throws {
        pollsViewModel.reset()
        homeViewModel.reset()
        leaderViewModel.reset()
        switch selectedTab.title {
        case "Home":
            await homeViewModel.loadInitialPostFeed(cityIds: citiesInRange)
        case "Polls":
            try await pollsViewModel.getInitialPolls(cityIds: citiesInRange)
        case "LeaderBoard":
            try await leaderViewModel.fetchMoreLeaderboards(cities: citiesInRange)
        default:
            break
            //
        }
    }
}

