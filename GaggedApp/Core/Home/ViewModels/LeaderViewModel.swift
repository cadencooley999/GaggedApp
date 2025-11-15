//
//  LeaderViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/25/25.
//

import Foundation
import SwiftUI

enum rankList {
    case allTimeUp
    case thisWeekUp
    case allTimeDown
}

@MainActor
final class LeaderViewModel: ObservableObject {
    
    // Get 5 most downvoted
    // Get 5 most upvoted
    // Get most upvoted this week + number of comments
    
    @Published var hasLoaded: Bool = false
    @Published var allTimeUp: [PostModel] = []
    @Published var thisWeekUp: [PostModel] = []
    @Published var allTimeDown: [PostModel] = []
    
    let postManager = FirebasePostManager.shared
    
    func fetchLeaderboardsIfNeeded() async throws {
        guard !hasLoaded else {return}
        let allUp = try await postManager.getTopUpsAllTime()
        let thisWeek = try await postManager.getTopUpsThisWeek()
        let allDown = try await postManager.getTopDownsAllTime()
        
        allTimeUp = allUp
        thisWeekUp = thisWeek
        allTimeDown = allDown
        hasLoaded = true
    }
    
    func fetchMoreLeaderboards() async throws {
        let allUp = try await postManager.getTopUpsAllTime()
        let thisWeek = try await postManager.getTopUpsThisWeek()
        let allDown = try await postManager.getTopDownsAllTime()
        
        allTimeUp = allUp
        thisWeekUp = thisWeek
        allTimeDown = allDown
    }
    
    func getUpStat(index: Int, list: rankList) -> Int? {
        switch list {
        case .allTimeUp:
            guard allTimeUp.indices.contains(index) else { return nil }
            return allTimeUp[index].upvotes
        case .thisWeekUp:
            guard thisWeekUp.indices.contains(index) else { return nil }
            return thisWeekUp[index].upvotesThisWeek
        case .allTimeDown:
            guard allTimeDown.indices.contains(index) else { return nil }
            return allTimeDown[index].downvotes
        }
    }
}
