//
//  GaggedAppApp.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import SwiftUI
import Foundation
import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
      if !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") {
          FirebaseApp.configure()
      }

    return true
  }
}

@main
struct GaggedAppApp: App {
    
    @AppStorage("hasOnboarded") var hasOnboarded = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("userId") var userId = ""
    @StateObject var homeViewModel: HomeViewModel
    @StateObject var addPostViewModel = AddPostViewModel()
    @StateObject var profileViewModel = ProfileViewModel()
    @StateObject var postViewModel = PostViewModel()
    @StateObject var searchViewModel: SearchViewModel
//    @StateObject var eventsViewModel = EventsViewModel()
//    @StateObject var eventViewModel = EventViewModel()
    @StateObject var leaderViewModel = LeaderViewModel()
    @StateObject var onBoardingViewModel = OnboardingViewModel()
    @StateObject var settingsViewModel = SettingsViewModel()
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var locationManager = LocationManager()
    @StateObject var pollsViewModel: PollsViewModel
    @StateObject var feedStore = FeedStore()
    @StateObject private var windowSize = WindowSize()
    
    init() {
        let feedStore = FeedStore()
        _feedStore = StateObject(wrappedValue: feedStore)

        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(feedStore: feedStore)
        )

        _searchViewModel = StateObject(
            wrappedValue: SearchViewModel(feedStore: feedStore)
        )
        
        _pollsViewModel = StateObject(wrappedValue: PollsViewModel(feedStore: feedStore))
        
        if userId != "" {
            CoreDataManager.setup(userId: userId)
        }
        
        Task {
            let newTags = try await TagManager.shared.loadTags()
            let newCategories = try await TagManager.shared.loadCategories()
            guard !newTags.isEmpty && !newCategories.isEmpty else {
                return
            }
            TagManager.shared.tagList = newTags
            TagManager.shared.categories = newCategories
        }
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                if isLoggedIn && userId != "" {
                    GeometryReader { geo in
                        TabHomeView()
                            .onAppear {
                                windowSize.size = geo.size
                            }
                            .onChange(of: geo.size) { newSize in
                                windowSize.size = newSize
                            }
                            .environmentObject(homeViewModel)
                            .environmentObject(addPostViewModel)
                            .environmentObject(profileViewModel)
                            .environmentObject(searchViewModel)
                            .environmentObject(postViewModel)
    //                        .environmentObject(eventsViewModel)
    //                        .environmentObject(eventViewModel)
                            .environmentObject(leaderViewModel)
                            .environmentObject(settingsViewModel)
                            .environmentObject(locationManager)
                            .environmentObject(pollsViewModel)
                            .environmentObject(feedStore)
                    }
                    .environmentObject(windowSize)
                }
                else {
                    GeometryReader { geo in
                        LoginView()
                            .onAppear {
                                windowSize.size = geo.size
                            }
                            .onChange(of: geo.size) { newSize in
                                windowSize.size = newSize
                            }
                            .environmentObject(loginViewModel)
                    }
                    .environmentObject(windowSize)
                }
            }
            else {
                GeometryReader { geo in
                    OnboardingView()
                        .onAppear {
                            windowSize.size = geo.size
                        }
                        .onChange(of: geo.size) { newSize in
                            windowSize.size = newSize
                        }
                        .environmentObject(onBoardingViewModel)
                        .environmentObject(locationManager)
                }
                .environmentObject(windowSize)
            }
        }
    }
}

final class WindowSize: ObservableObject {
    @Published var size: CGSize = .zero
}
