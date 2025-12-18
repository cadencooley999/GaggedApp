//
//  OneSearch.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/1/25.
//

import SwiftUI
import Foundation

struct OneSearch: View {
    
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var locationManager: LocationManager
//    @EnvironmentObject var eventViewModel: EventViewModel
    
    @Binding var hideTabBar: Bool
    @Binding var selectedTab: TabBarItem
    @Binding var showPostView: Bool
    @Binding var showEventView: Bool
    @Binding var selectedPost: PostModel?
    @Binding var searchViewFocused: Bool
    @FocusState var isFocused: Bool
    
    private var filteredEverything: [MixedType] {
        var filtered = searchViewModel.everythingList

        return filtered
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    if searchViewModel.isLoading {
                        ProgressView()
                            .tint(Color.theme.darkBlue)
                            .padding(.top, 300)
                    }
                    segmentedController
                }
                .padding(.top, 55)
            }
            .onScrollPhaseChange({ oldPhase, newPhase in
                if newPhase == .interacting {
                    UIApplication.shared.endEditing()
                }
            })
            VStack(spacing: 0){
                header
                    .frame(height: 55)
                    .background(.regularMaterial)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 { // left swipe
                        UIApplication.shared.endEditing()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard")
                        }
                        searchViewModel.searchText = ""
                    }
                }
        )
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                searchViewModel.addSubscribers {
                    locationManager.citiesInRange
                }
                isFocused = true
            })
        }
        .onChange(of: isFocused, perform: { isFocused in
            dismissKeyboard(isFocused: isFocused)
        })
    }
    
    func dismissKeyboard(isFocused: Bool) {
        if isFocused {
            hideTabBar = true
        }
        else {
            hideTabBar = false
        }
    }
    
    var header: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.theme.darkBlue)
                    .onTapGesture {
                        print("CHEV TAPPED")
                        UIApplication.shared.endEditing()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = TabBarItem(iconName: "LeaderIcon", title: "LeaderBoard")
                        }
                        searchViewModel.searchText = ""
                    }
                    .padding(.horizontal)
                Spacer()
                TextField("Search posts and events...", text: $searchViewModel.oneSearchText)
                    .focused($isFocused)
                    .onChange(of: isFocused) { shouldFocus in
                        searchViewFocused = shouldFocus
                    }
                    .onChange(of: searchViewFocused) { searchViewFocused in
                        isFocused = searchViewFocused
                    }
            }
            .padding()
            Divider()
        }

    }
    
    var segmentedController: some View {
        HStack(spacing: 0) {
            Text("Posts")
                .padding()
                .background(searchViewModel.selectedFilter == "Posts" ? Color.theme.darkBlue : Color.clear)
                .onTapGesture {
                    print("Tapped Posts")
                    if searchViewModel.selectedFilter == "Posts" {
                        searchViewModel.selectedFilter = ""
                    }
                    else {
                        searchViewModel.selectedFilter = "Posts"
                    }
                }
                .padding(.horizontal)
            Text("Events")
                .padding()
                .background(searchViewModel.selectedFilter == "Events" ? Color.theme.darkBlue : Color.clear)
                .onTapGesture {
                    print("Tapped Event")
                    if searchViewModel.selectedFilter == "Events" {
                        searchViewModel.selectedFilter = ""
                    }
                    else {
                        searchViewModel.selectedFilter = "Events"
                    }
                }
                .padding(.horizontal)
        }
    }
}

