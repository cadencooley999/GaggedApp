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
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var leaderViewModel: LeaderViewModel
    
    @Binding var showSearchView: Bool
    @Binding var selectedTab: TabBarItem
    @Binding var showProfileView: Bool
    @Binding var showCityPicker: Bool
    
    @State var rotation: Double = 0
    
    @State var isPressed: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: App name only (Logo removed as requested)
            Text("Ga!")
                .font(.title.bold())
                .foregroundColor(Color.theme.accent)
            
            Spacer()
            
            HStack(spacing: 0){
                Text(locationManager.selectedCity?.city ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(Color.theme.darkBlue)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive().tint(Color.theme.lightBlue.opacity(0.2)))
                    .onTapGesture {
                        showCityPicker = true
                    }
//                    .background(
//                        RoundedRectangle(cornerRadius: 20)
//                            .fill(Color.theme.lightBlue.opacity(0.2))
//                    )
//                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
//                    .scaleEffect(isPressed ? 0.96 : 1.0)
//                    .animation(.easeOut(duration: 0.12), value: isPressed)
//                    .gesture(
//                        DragGesture(minimumDistance: 0)
//                            .onChanged { _ in
//                                if !isPressed { isPressed = true }
//                            }
//                            .onEnded { _ in
//                                isPressed = false
//                                showCityPicker = true
//                            }
//                    )
                
                Button(action: {
                    Task {
                        rotation += 360
                        do {
                            locationManager.clearLocationData()
                            let cities = try await locationManager.requestLocation()
                            pollsViewModel.reset()
                            homeViewModel.reset()
                            leaderViewModel.reset()
                            switch selectedTab.title {
                            case "Home":
                                await homeViewModel.loadInitialPostFeed(cityIds: cities)
                            case "Polls":
                                try await pollsViewModel.getInitialPolls(cityIds: cities)
                            case "LeaderBoard":
                                try await leaderViewModel.fetchMoreLeaderboards(cities: cities, blockedUserIds: Array(Set(homeViewModel.blocked + homeViewModel.blockedBy)))
                            default:
                                break
                            }
                        } catch {
                            print("User denied location permission")
                            
                            // show alert / fallback city
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(Color.theme.darkBlue)
                        .rotationEffect(Angle(degrees: rotation))
                        .animation(.spring(duration: 0.3), value: rotation)
                        .frame(width: 22, height: 22)
                        .padding(8) // Gives a good tap target size
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            Image(systemName: "person")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
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


