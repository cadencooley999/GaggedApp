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
            Color(.systemGroupedBackground).ignoresSafeArea()
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
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundStyle(.secondary)

                TextField("Search Cities", text: $homeViewModel.citySearchText)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(14)
            .glassEffect()
            .padding(.horizontal, 8)
            Spacer()
            Text("Done")
                .font(.subheadline.bold())
                .foregroundStyle(Color.theme.darkBlue)
                .padding()
                .glassEffect(.regular.tint(Color.theme.lightBlue.opacity(0.2)), in: .rect(cornerRadius: 30))
                .onTapGesture {
                    showCitySelectionView = false
                }
        }
    }
    
    var citiesSection: some View {
        VStack(spacing: 12) {
            if let city = locationManager.selectedCity {
                Text("Current City")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.gray)
                    .padding(.horizontal)
                VStack {
                    cityRow(city: city, isRecent: false, isCurrent: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cityTapped(city: city)
                        }
                }
                .glassEffect(in: .rect(cornerRadius: 30))
            }
            
            if homeViewModel.citySearchText == "" && !recentCities.isEmpty {
                Text("Recent Cities")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.gray)
                    .padding(.horizontal)
                VStack(spacing: 0) {
                    ForEach(recentCities) { city in
                        cityRow(city: city, isRecent: true, isCurrent: false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                cityTapped(city: city)
                            }
                        if city.id != recentCities.last?.id { Divider() }
                    }
                }
                .glassEffect(in: .rect(cornerRadius: 30))

            }
            
            Text("All Cities")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.gray)
                .padding(.horizontal)
            
            LazyVStack(spacing: 0) {
                ForEach(homeViewModel.allCitiesList.filter({ $0.id != locationManager.selectedCity?.id })) { city in
                    cityRow(city: city, isRecent: recentIDs.contains(city.id), isCurrent: false)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cityTapped(city: city)
                        }
                    if city.id != homeViewModel.allCitiesList.filter({ $0.id != locationManager.selectedCity?.id }).last?.id { Divider() }
                }
            }
            .glassEffect(in: .rect(cornerRadius: 30))

        }
    }
    
    func cityTapped(city: City) {
        if !addPostVm.selectedCities.contains(where: { $0.id == city.id }) {
            if addPostVm.selectedCities.count < 2 {
                addPostVm.selectedCities.append(city)
            }
        }
        else {
            addPostVm.selectedCities.removeAll(where: { $0.id == city.id })
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
}

private struct SectionCard<Content: View, Toolbar: View>: View {
    let title: String?
    let content: Content
    let toolbar: Toolbar

    init(title: String? = nil,
         @ViewBuilder content: () -> Content,
         @ViewBuilder toolbar: () -> Toolbar = { EmptyView() }) {
        self.title = title
        self.content = content()
        self.toolbar = toolbar()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    toolbar
                }
            }
            content
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 4)
    }
}

#Preview {
    CitySelectionView(showCitySelectionView: .constant(true))
}
