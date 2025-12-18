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
    
    @Published var oneSearchText: String = ""
    @Published var searchText: String = ""
    @Published var eventSearchText: String = ""
    @Published var everythingList: [MixedType] = []
    @Published var postMatrix: [[PostModel]] = []
    @Published var eventList: [EventModel] = []
    @Published var columns: Int = 2
    @Published var allPostsNearby: [PostModel] = []
    @Published var allEventsNearby: [EventModel] = []
    @Published var selectedFilter: String = ""
    @Published var isLoading: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    
    let postManager = FirebasePostManager.shared
    let eventManager = EventManager.shared

    let heights: [CGFloat] = [220]
    
    func addSubscribers(cityIDsProvider: @escaping () -> [String]) {
        $searchText
            .debounce(for: 0.05, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let cityIDs = cityIDsProvider()
                if self.searchText == "" && self.hasOnboarded && self.isLoggedIn {
                    Task {
                        try await self.fetchPosts(cities: cityIDs)
                        self.isLoading = false
                        print("task ended")
                    }
                }
                else {
                    if allPostsNearby == [] {
                        Task {
                            self.allPostsNearby = try await self.postManager.getAllPostsNearby(cities: cityIDs)
                        }
                    }
                    self.getPostsFromSearch(cities: cityIDs, allPosts: self.allPostsNearby)
                }
            }
            .store(in: &cancellables)
        
        $eventSearchText
            .debounce(for: 0.05, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let cityIDs = cityIDsProvider()
                if self.eventSearchText == "" && self.hasOnboarded && self.isLoggedIn {
                    Task {
                        try await self.fetchEvents(cities: cityIDs)
                    }
                }
                else {
                    if allEventsNearby == [] {
                        Task {
                            self.allEventsNearby = try await self.eventManager.getAllEventsNearby(cities: cityIDs)
                        }
                    }
                    self.getEventsFromSearch(cities: cityIDs, allEvents: self.allEventsNearby)
                }
            }
            .store(in: &cancellables)
        
        $oneSearchText
            .debounce(for: 0.05, scheduler: DispatchQueue.main)
            .sink {[weak self] _ in
                print("recieving text")
                guard let self = self else { return }
                let cityIDs = cityIDsProvider()
                if self.oneSearchText != "" {
                    Task { [weak self] in
                        guard let self = self else { return }
                        print("in guards")
                        async let eventsTask: [EventModel] = self.allEventsNearby.isEmpty
                            ? self.eventManager.getAllEventsNearby(cities: cityIDs)
                            : self.allEventsNearby

                        async let postsTask: [PostModel] = self.allPostsNearby.isEmpty
                            ? self.postManager.getAllPostsNearby(cities: cityIDs)
                            : self.allPostsNearby

                        // Wait for BOTH
                        self.allEventsNearby = try await eventsTask
                        self.allPostsNearby = try await postsTask

                        print("Found both")
                        // Now searchMixed AFTER the above
                        try await self.searchMixed(cities: cityIDs)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func mixAndOrder(postList: [PostModel], eventList: [EventModel]) -> [MixedType] {
        var newArray: [MixedType] = []
        var posts = postList
        var events = eventList

        while !posts.isEmpty || !events.isEmpty {
            // Add up to 2 posts
            if !posts.isEmpty {
                let count = min(2, posts.count)
                newArray.append(contentsOf: posts.prefix(count).map { .post($0) })
                posts.removeFirst(count)
            }

            // Add 1 event
            if !events.isEmpty {
                newArray.append(.event(events.removeFirst()))
            }
        }

        // Optional: filter out invalid IDs
        return newArray.filter {
            switch $0 {
            case .post(let p):  return !p.id.isEmpty
            case .event(let e): return !e.id.isEmpty
            }
        }
    }
    
    func searchMixed(cities: [String]) async throws {
        let searchKeyword = oneSearchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("Searching for: \(searchKeyword)")
        
        let searchedPosts = try await postManager.getPostsFromSearch(keyword: searchKeyword, allPostsNearby: allPostsNearby)
        
        let searchedEvents = try await eventManager.getEventsFromSearch(keyword: searchKeyword, allEventsNearby: allEventsNearby)
        
        everythingList = mixAndOrder(postList: searchedPosts, eventList: searchedEvents)
    }
    
    func fetchPosts(cities: [String]) async throws {
        let posts = try await postManager.getPosts(from: cities)
//        var posts = FirebasePostManager.shared.mockPosts
        let postLists = splitListSize(postlist: posts, columns: columns)
        postMatrix = postLists
    }
    
    func getPostsFromSearch(cities: [String], allPosts: [PostModel]) {
        Task {
            let posts = try await postManager.getPostsFromSearch(keyword: searchText, allPostsNearby: allPostsNearby)
            postMatrix = splitListSize(postlist: posts, columns: columns)
            
        }
    }
    
    func fetchEvents(cities: [String]) async throws {
        print("Fetching events in search")
        let events = try await eventManager.getEvents(from: cities)
        eventList = events
    }
    
    func getEventsFromSearch(cities: [String], allEvents: [EventModel]) {
        Task {
            let events = try await eventManager.getEventsFromSearch(keyword: eventSearchText, allEventsNearby: allEventsNearby)
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
