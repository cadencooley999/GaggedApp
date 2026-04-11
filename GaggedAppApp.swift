//
//  GaggedAppApp.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import SwiftUI
import Foundation
import UIKit
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        print("Did finish launching")

        // Initialize Firebase
        FirebaseApp.configure()

        // Set delegates
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        Messaging.messaging().delegate = NotificationManager.shared
        
        print("📡 Firebase APNs token:", Messaging.messaging().apnsToken as Any)

        return true
    }

    // MARK: - APNs registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ APNs token received")
        // Pass device token to FCM
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications:", error)
    }
}


    
@main
struct GaggedAppApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @AppStorage("hasOnboarded") var hasOnboarded = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("userId") var userId = ""
    @AppStorage("isBanned") var isBanned = false
    
    @StateObject private var windowSize = WindowSize()
    @StateObject var locationManager = LocationManager.shared
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var onBoardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                if isLoggedIn && !userId.isEmpty && !isBanned {
                    
                    AuthenticatedRootView(userId: userId)
                        .id(userId) // 🔥 FULL RESET HERE
                        .environmentObject(windowSize)
                    
                } else if isBanned {
                    BannedView()
                    
                } else {
                    GeometryReader { geo in
                        LoginView()
                            .onAppear { windowSize.size = geo.size }
                            .onChange(of: geo.size) { windowSize.size = $0 }
                            .environmentObject(loginViewModel)
                    }
                    .environmentObject(windowSize)
                }
                
            } else {
                
                GeometryReader { geo in
                    OnboardingView()
                        .onAppear { windowSize.size = geo.size }
                        .onChange(of: geo.size) { windowSize.size = $0 }
                        .environmentObject(onBoardingViewModel)
                        .environmentObject(locationManager)
                }
                .environmentObject(windowSize)
            }
        }
    }
}

struct AuthenticatedRootView: View {
    
    let userId: String
    
    @StateObject private var feedStore: FeedStore
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var pollsViewModel: PollsViewModel
    
    @StateObject private var addPostViewModel = AddPostViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var postViewModel = PostViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var leaderViewModel = LeaderViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var inspectionViewModel = InspectionViewModel()
    @StateObject var locationManager = LocationManager.shared
    @EnvironmentObject var windowSize: WindowSize
    
    init(userId: String) {
        self.userId = userId
        
        let feedStore = FeedStore()
        _feedStore = StateObject(wrappedValue: feedStore)
        
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(feedStore: feedStore)
        )
        
        _pollsViewModel = StateObject(
            wrappedValue: PollsViewModel(feedStore: feedStore)
        )
        
        if !userId.isEmpty {
            CoreDataManager.setup(userId: userId)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            TabHomeView()
                .onAppear {
                    windowSize.size = geo.size
                }
                .onChange(of: geo.size) {
                    windowSize.size = $0
                }
                .environmentObject(homeViewModel)
                .environmentObject(addPostViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(searchViewModel)
                .environmentObject(postViewModel)
                .environmentObject(leaderViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(locationManager)
                .environmentObject(pollsViewModel)
                .environmentObject(inspectionViewModel)
                .environmentObject(feedStore)
        }
        .onAppear {
            feedStore.getBlockedLists(userId: userId)
        }
    }
}

//@main
//struct GaggedAppApp: App {
//    
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    
//    @AppStorage("hasOnboarded") var hasOnboarded = false
//    @AppStorage("isLoggedIn") var isLoggedIn = false
//    @AppStorage("userId") var userId = ""
//    @AppStorage("isBanned") var isBanned = false
//    @StateObject var homeViewModel: HomeViewModel
//    @StateObject var addPostViewModel = AddPostViewModel()
//    @StateObject var profileViewModel = ProfileViewModel()
//    @StateObject var postViewModel = PostViewModel()
//    @StateObject var searchViewModel: SearchViewModel
////    @StateObject var eventsViewModel = EventsViewModel()
////    @StateObject var eventViewModel = EventViewModel()
//    @StateObject var leaderViewModel = LeaderViewModel()
//    @StateObject var onBoardingViewModel = OnboardingViewModel()
//    @StateObject var settingsViewModel = SettingsViewModel()
//    @StateObject var loginViewModel = LoginViewModel()
//    @StateObject var inspectionViewModel = InspectionViewModel()
//    @StateObject var locationManager = LocationManager.shared
//    @StateObject var pollsViewModel: PollsViewModel
//    @StateObject var feedStore = FeedStore()
//    @StateObject private var windowSize = WindowSize()
//    
//    init() {
//        let feedStore = FeedStore()
//        _feedStore = StateObject(wrappedValue: feedStore)
//
//        _homeViewModel = StateObject(
//            wrappedValue: HomeViewModel(feedStore: feedStore)
//        )
//        
//        _pollsViewModel = StateObject(wrappedValue: PollsViewModel(feedStore: feedStore))
//        
//        _searchViewModel = StateObject(wrappedValue: SearchViewModel())
//        
//        if userId != "" {
//            CoreDataManager.setup(userId: userId)
//        }
//        
//        Task {
//            let newTags = try await TagManager.shared.loadTags()
//            let newCategories = try await TagManager.shared.loadCategories()
//            guard !newTags.isEmpty && !newCategories.isEmpty else {
//                return
//            }
//            TagManager.shared.tagList = newTags
//            TagManager.shared.categories = newCategories
//        }
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            if hasOnboarded {
//                if isLoggedIn && userId != "" && !isBanned {
//                    GeometryReader { geo in
//                        TabHomeView()
//                            .id(userId)
//                            .onAppear {
//                                windowSize.size = geo.size
//                            }
//                            .onChange(of: geo.size) { newSize in
//                                windowSize.size = newSize
//                            }
//                            .environmentObject(homeViewModel)
//                            .environmentObject(addPostViewModel)
//                            .environmentObject(profileViewModel)
//                            .environmentObject(searchViewModel)
//                            .environmentObject(postViewModel)
//    //                        .environmentObject(eventsViewModel)
//    //                        .environmentObject(eventViewModel)
//                            .environmentObject(leaderViewModel)
//                            .environmentObject(settingsViewModel)
//                            .environmentObject(locationManager)
//                            .environmentObject(pollsViewModel)
//                            .environmentObject(inspectionViewModel)
//                            .environmentObject(feedStore)
//                    }
//                    .onAppear {
//                        feedStore.getBlockedLists(userId: userId)
//                    }
//                    .environmentObject(windowSize)
//                }
//                else if isBanned {
//                    BannedView()
//                }
//                else {
//                    GeometryReader { geo in
//                        LoginView()
//                            .onAppear {
//                                windowSize.size = geo.size
//                            }
//                            .onChange(of: geo.size) { newSize in
//                                windowSize.size = newSize
//                            }
//                            .environmentObject(loginViewModel)
//                    }
//                    .environmentObject(windowSize)
//                }
//            }
//            else {
//                GeometryReader { geo in
//                    OnboardingView()
//                        .onAppear {
//                            windowSize.size = geo.size
//                        }
//                        .onChange(of: geo.size) { newSize in
//                            windowSize.size = newSize
//                        }
//                        .environmentObject(onBoardingViewModel)
//                        .environmentObject(locationManager)
//                }
//                .environmentObject(windowSize)
//            }
//        }
//    }
//}

final class WindowSize: ObservableObject {
    @Published var size: CGSize = .zero
}
