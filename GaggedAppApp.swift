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
    @StateObject var homeViewModel = HomeViewModel()
    @StateObject var addPostViewModel = AddPostViewModel()
    @StateObject var profileViewModel = ProfileViewModel()
    @StateObject var postViewModel = PostViewModel()
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var eventsViewModel = EventsViewModel()
    @StateObject var eventViewModel = EventViewModel()
    @StateObject var leaderViewModel = LeaderViewModel()
    @StateObject var onBoardingViewModel = OnboardingViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                TabHomeView()
                    .environmentObject(homeViewModel)
                    .environmentObject(addPostViewModel)
                    .environmentObject(profileViewModel)
                    .environmentObject(searchViewModel)
                    .environmentObject(postViewModel)
                    .environmentObject(eventsViewModel)
                    .environmentObject(eventViewModel)
                    .environmentObject(leaderViewModel)
            }
            else {
                OnboardingView()
                    .environmentObject(onBoardingViewModel)
            }
        }
    }
}
