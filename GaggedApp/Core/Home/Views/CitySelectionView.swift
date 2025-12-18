//
//  CitySelectionView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/20/25.
//

import SwiftUI

struct CitySelectionView: View {
    @AppStorage("lastCityIds") var lastCityIds = "[]"
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var addPostVm: AddPostViewModel
    
    @Binding var showCitySelectionView: Bool

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
        .onAppear {
            recentIDs = decodeList(from: lastCityIds)
            recentCities = cityManager.getCities(ids: recentIDs)
            homeViewModel.addSubscribers(recentCities)
            print(lastCityIds)
        }
    }
    
    var header: some View {
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
    
    var citiesSection: some View {
        VStack(spacing: 12) {
            if let city = locationManager.selectedCity {
                cityRow(city: city, isRecent: false, isCurrent: true)
                    .background(
                        Color.theme.lightGray.opacity(0.15)
                            .cornerRadius(15)
                    )
                    .onTapGesture {
                        cityTapped(city: city)
                    }
            }
            
            LazyVStack(spacing: 0) {

                // Recent Cities
                if homeViewModel.citySearchText == "" {
                    ForEach(recentCities) { city in
                        cityRow(city: city, isRecent: true, isCurrent: false)
                            .onTapGesture {
                                cityTapped(city: city)
                            }
                        Divider()
                    }
                }

                // All Cities minus recent
                ForEach(homeViewModel.allCitiesList.filter({$0.id != locationManager.selectedCity?.id})) { city in
                    if recentIDs.contains(city.id) {
                        cityRow(city: city, isRecent: true, isCurrent: false)
                            .onTapGesture {
                                cityTapped(city: city)
                            }
                    }
                    else  {
                        cityRow(city: city, isRecent: false, isCurrent: false)
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
        if !addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
            addPostVm.selectedCities.append(city)
            showCitySelectionView = false
        }
    }

    // MARK: - Reusable row (NO new functionality, just layout cleanup)
    private func cityRow(city: City, isRecent: Bool, isCurrent: Bool) -> some View {
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
            
            if isCurrent {
                Text(" Current")
                    .font(.caption)
                    .foregroundStyle(Color.theme.darkBlue)
                    .italic()
                    .padding(.leading, 16)
            }

            Spacer()
            if addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
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
    
//
//    @EnvironmentObject var addPostVm: AddPostViewModel
//    
//    @Binding var showCitySelectionView: Bool
//    
//    @FocusState var isFocused: Bool
//    
//    var body: some View {
//        ZStack {
//            Color.theme.background
//                .ignoresSafeArea()
//            ScrollView {
//                header
//                cityList
//            }
//        }
//
//    }
//    
//    var header: some View {
//        VStack(spacing: 0){
//            HStack {
//                Image(systemName: "chevron.left")
//                    .font(.headline)
//                    .onTapGesture {
//                        print("CHEV TAPPED")
//                        isFocused = false
//                        showCitySelectionView = false
//                    }
//                    .padding(.trailing, 8)
//                TextField("Search cities...", text: $addPostVm.query)
//                    .focused($isFocused)
//                    .padding(8)
//                    .background(Color.theme.lightGray.opacity(0.3).cornerRadius(20))
//                    .onChange(of: addPostVm.query) { _ in
//                        print(addPostVm.query)
//                        addPostVm.searchCities()
//                    }
//                
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//            Divider()
//        }
//        .background(Color.theme.background)
//    }
//    
//    var cityList: some View {
//        VStack {
//            ForEach(addPostVm.filteredCities) { city in
//                HStack(spacing: 0){
//                    Text(city.city)
//                        .italic()
//                        .font(.body)
//                    Text(", " + city.state_id)
//                        .font(.body)
//                        .italic()
//                    Spacer()
//                    if addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
//                        Image(systemName: "checkmark")
//                            .font(.body)
//                    }
//                    else {
//                        Image(systemName: "plus")
//                            .font(.body)
//                            .foregroundStyle(Color.theme.darkBlue)
//                    }
//                }
//                .frame(height: 35)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal)
//                .onTapGesture {
//                    if !addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
//                        addPostVm.selectedCities.append(city)
//                        showCitySelectionView = false
//                    }
//                }
//                Divider()
//            }
//        }
//    }
}

#Preview {
    CitySelectionView(showCitySelectionView: .constant(true))
}
