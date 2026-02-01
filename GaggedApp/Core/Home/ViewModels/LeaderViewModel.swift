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
    @Published var weekStats: [Int] = []
    @Published var isLoading: Bool = false
    
    let postManager = FirebasePostManager.shared
    
    func fetchLeaderboardsIfNeeded(cities: [String]) async throws {
        guard !hasLoaded else {return}
        self.isLoading = true
        defer {self.isLoading = false}
        do {
            async let allUp = postManager.getTopUpsAllTime(from: cities)
            async let thisWeek = postManager.getTopUpsThisWeek(from: cities)
            async let allDown = postManager.getTopDownsAllTime(from: cities)

            let (up, week, down) = try await (allUp, thisWeek, allDown)

            allTimeUp = up
            thisWeekUp = week.0
            allTimeDown = down
            
            weekStats = week.1
        } catch {
            throw NetworkErrors.ErrorFetching
        }
    }
    
    func fetchMoreLeaderboards(cities: [String]) async throws {
        self.isLoading = true
        defer {
            self.isLoading = false
        }
        
        allTimeUp.removeAll()
        thisWeekUp.removeAll()
        allTimeDown.removeAll()
        
        async let allUp = postManager.getTopUpsAllTime(from: cities)
        async let thisWeek = postManager.getTopUpsThisWeek(from: cities)
        async let allDown = postManager.getTopDownsAllTime(from: cities)

        do {
            let (up, week, down) = try await (allUp, thisWeek, allDown)
            
            allTimeUp.append(contentsOf: up)
            thisWeekUp.append(contentsOf: week.0)
            allTimeDown.append(contentsOf: down)
            
            weekStats = week.1
        } catch {
            throw NetworkErrors.ErrorFetching
        }
    }
    
    func getUpStat(index: Int) -> Int? {

        return 0
    }
}
