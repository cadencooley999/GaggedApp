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
    @Published var isLoading: Bool = false
    
    let postManager = FirebasePostManager.shared
    
    func fetchLeaderboardsIfNeeded(cities: [String]) async throws {
        guard !hasLoaded else {return}
        isLoading = true
        let allUp = try await postManager.getTopUpsAllTime(from: cities)
        let thisWeek = try await postManager.getTopUpsThisWeek(from: cities)
        let allDown = try await postManager.getTopDownsAllTime(from: cities)
        
        allTimeUp = allUp
        thisWeekUp = thisWeek
        allTimeDown = allDown
        hasLoaded = true
        isLoading = false
    }
    
    func fetchMoreLeaderboards(cities: [String]) async throws {
        print("GEtting leaders")
        allTimeUp = []
        thisWeekUp = []
        allTimeDown = []
        isLoading = true
        let allUp = try await postManager.getTopUpsAllTime(from: cities)
        let thisWeek = try await postManager.getTopUpsThisWeek(from: cities)
        let allDown = try await postManager.getTopDownsAllTime(from: cities)
        
        allTimeUp = allUp
        thisWeekUp = thisWeek
        allTimeDown = allDown
        isLoading = false
    }
    
    func getUpStat(index: Int, list: rankList) -> Int? {
//        switch list {
//        case .allTimeUp:
//            guard allTimeUp.indices.contains(index) else { return nil }
//            return allTimeUp[index].upvotes
//        case .thisWeekUp:
//            guard thisWeekUp.indices.contains(index) else { return nil }
//            return thisWeekUp[index].upvotesThisWeek
//        case .allTimeDown:
//            guard allTimeDown.indices.contains(index) else { return nil }
//            return allTimeDown[index].downvotes
//        }
        return 0
    }
}
