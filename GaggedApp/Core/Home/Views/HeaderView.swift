//
//  HeaderView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/23/25.
//

import SwiftUI

struct HeaderView: View {
    
//    let allTabs = [
//        TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard"),
//        TabBarItem(iconName: "HomeIcon", title: "Home"),
//        TabBarItem(iconName: "EventsIcon", title: "Events"),
//        TabBarItem(iconName: "ProfileIcon", title: "Profile")
//    ]
    @AppStorage("cityChoiceId") var cityChoiceId: String = ""
    
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var searchViewModel: SearchViewModel
//    @EnvironmentObject var eventsViewModel: EventsViewModel

    @Binding var showSearchView: Bool
    @Binding var selectedTab: TabBarItem
    @Binding var showProfileView: Bool
    @Binding var showCityPicker: Bool
    
    @State var isPressed: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
        // Left: App name only (Logo removed as requested)
            Text("Gagged")
                .font(.title2.bold())
                .foregroundColor(Color.theme.darkBlue)
            
            Spacer()
            
            HStack(spacing: 0){
                Text(locationManager.selectedCity?.city ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(Color.theme.darkBlue)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.theme.lightBlue.opacity(0.2))
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
                        .scaleEffect(isPressed ? 0.96 : 1.0)
                        .animation(.easeOut(duration: 0.12), value: isPressed)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isPressed { isPressed = true }
                                }
                                .onEnded { _ in
                                    isPressed = false
                                    showCityPicker = true
                                }
                        )

                Button(action: {
                    Task {
                        searchViewModel.allPostsNearby.removeAll()
                        searchViewModel.allEventsNearby.removeAll()
                        cityChoiceId = ""
                        print("CITYCHOICEHERE", cityChoiceId)
                        await locationManager.requestLocation()
                        try await homeViewModel.fetchMorePosts(cities: locationManager.citiesInRange)
//                        try await eventsViewModel.fetchMoreEvents(cities: locationManager.citiesInRange)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(Color.theme.darkBlue)
                        .padding(8) // Gives a good tap target size
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            Image(systemName: "person")
                .font(.title3)
                .foregroundColor(Color.theme.darkBlue)
                .padding(8)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showProfileView = true
                    }
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(height: 55)
    }
}
