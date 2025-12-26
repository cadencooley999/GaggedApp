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
        async let allUp = postManager.getTopUpsAllTime(from: cities)
        async let thisWeek = postManager.getTopUpsThisWeek(from: cities)
        async let allDown = postManager.getTopDownsAllTime(from: cities)

        let (up, week, down) = try await (allUp, thisWeek, allDown)

        allTimeUp = up
        thisWeekUp = week
        allTimeDown = down
        hasLoaded = true
        isLoading = false
    }
    
    func fetchMoreLeaderboards(cities: [String]) async throws {
        print("GEtting leaders")
        isLoading = true
        async let allUp = postManager.getTopUpsAllTime(from: cities)
        async let thisWeek = postManager.getTopUpsThisWeek(from: cities)
        async let allDown = postManager.getTopDownsAllTime(from: cities)

        let (up, week, down) = try await (allUp, thisWeek, allDown)

        allTimeUp = up
        thisWeekUp = week
        allTimeDown = down
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
