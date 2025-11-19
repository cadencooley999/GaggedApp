//
//  SearchViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    
    @AppStorage("hasOnboarded") var hasOnboarded = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    @Published var searchText: String = ""
    @Published var eventSearchText: String = ""
    @Published var postMatrix: [[PostModel]] = []
    @Published var eventList: [EventModel] = []
    @Published var columns: Int = 2
    
    var cancellables = Set<AnyCancellable>()
    
    let postManager = FirebasePostManager.shared
    let eventManager = EventManager.shared

    init() {
        addSubscribers()
        print("subs added")
    }

    let heights: [CGFloat] = [220]
    
    func addSubscribers() {
        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                if self.searchText == "" && self.hasOnboarded && self.isLoggedIn {
                    Task {
                        try await self.fetchPosts()
                    }
                }
                else {
                    self.getPostsFromSearch()
                }
            }
            .store(in: &cancellables)
        $eventSearchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                if self.eventSearchText == "" && self.hasOnboarded && self.isLoggedIn {
                    Task {
                        try await self.fetchEvents()
                    }
                }
                else {
                    self.getEventsFromSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchPosts() async throws {
        let posts = try await postManager.getPosts()
//        var posts = FirebasePostManager.shared.mockPosts
        let postLists = splitListSize(postlist: posts, columns: columns)
        postMatrix = postLists
    }
    
    func getPostsFromSearch() {
        Task {
            let posts = try await postManager.getPostsFromSearch(keyword: searchText)
            postMatrix = splitListSize(postlist: posts, columns: columns)
        }
    }
    
    func fetchEvents() async throws {
        let events = try await eventManager.getEvents()
        eventList = events
    }
    
    func getEventsFromSearch() {
        Task {
            let events = try await eventManager.getEventsFromSearch(keyword: eventSearchText)
            eventList = events
        }
    }
    
    func splitListSize(postlist: [PostModel], columns: Int) -> [[PostModel]] {
        guard columns > 0 else { return [] }
        
        var postGrid: [[PostModel]] = Array(repeating: [], count: columns)
        var columnHeights: [Int] = Array(repeating: 0, count: columns)
        
        for post in postlist {
            var p = post
            p.height = heights.randomElement() ?? 120
            
            // find shortest column
            if let minIndex = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) {
                postGrid[minIndex].append(p)
                columnHeights[minIndex] += Int(p.height)
            }
        }
        
        return postGrid
    }
}
