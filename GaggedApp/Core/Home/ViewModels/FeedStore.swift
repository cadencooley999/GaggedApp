//
//  FeedStore.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/24/25.
//
import SwiftUI

@MainActor
final class FeedStore: ObservableObject {
    
    @AppStorage("userId") var userId = ""
    
    @Published var allPostsTriggered: Bool = false
    @Published var allPollsTriggered: Bool = false
    @Published var loadedPosts: [PostModel] = []
    @Published var loadedPolls: [PollWithOptions] = []
    @Published var selectedCityIDs: [String] = []
    @Published var blocked: Set<String> = []
    @Published var blockedBy: Set<String> = []
    @Published var hasLoadedBlocked: Bool = false
    
    func getBlockedLists(userId: String) {
        Task {
            if !userId.isEmpty {
               try await fetchBlockedLists(userId)
            }
        }
    }
    
    func fetchBlockedLists(_ userId: String) async throws {
        let blocked = try await BlockingManager.shared.fetchBlocked(userId: userId)
        let blockedBy = try await BlockingManager.shared.fetchBlockedBy(userId: userId)
        
        self.blocked = blocked
        self.blockedBy = blockedBy
        
        self.hasLoadedBlocked = true
    }
    
}
