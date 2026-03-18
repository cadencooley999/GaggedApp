//
//  HomeViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    let feedStore: FeedStore
    private var ingestedPostIDs = Set<String>()

    @Published var hasLoaded = false
    @Published var allCitiesList: [City] = []
    @Published var citySearchText: String = ""
    @Published var postMatrix: [[PostModel]] = []
    @Published var columns: Int = 3
    @Published var isLoading: Bool = false
    @Published var hasMore = true

    private var cursor: FeedCursor? = nil
    
    let storageManager = StorageManager.shared
    let postManager = FirebasePostManager.shared
    let cityManager = CityManager.shared
    var locationManager: LocationManager
    
    let heights: [CGFloat] = [240, 200, 300]
    
    var cancellables: Set<AnyCancellable> = []

    init(
        feedStore: FeedStore,
        locationManager: LocationManager = .shared
    ) {
        self.feedStore = feedStore
        self.locationManager = locationManager

        bindFeedStore()
        bindLocationUpdates()
    }
    
    private func bindLocationUpdates() {
        locationManager.feedReload
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                print("feed reload trigger received")
                self.fetchMorePostsNonAsync(cities: locationManager.citiesInRange)
            }
            .store(in: &cancellables)
    }
    
    private func bindFeedStore() {
        feedStore.$loadedPosts
            .sink { [weak self] posts in
                guard let self else { return }

                // 1) Update existing items in the matrix (e.g., vote counts), preserving height
                let updates = posts.filter { self.ingestedPostIDs.contains($0.id) }
                if !updates.isEmpty {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.updatePostsInMatrix(with: updates)
                    }
                }

                // 2) Append only truly new posts to the matrix
                let newPosts = posts.filter { self.ingestedPostIDs.insert($0.id).inserted }
                if !newPosts.isEmpty {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.appendPostsToMatrix(posts: newPosts, columns: self.columns)
                    }
                }
            }
            .store(in: &cancellables)
        
        // need to make it not reload whole list.
    }
    
    func bindCitySearch(recentCities: [City]) {
        $citySearchText
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.allCitiesList = self.searchCities(recentCities)
            }
            .store(in: &cancellables)
    }
    
    func removePostFromFeed(postId: String) {
        feedStore.loadedPosts.removeAll(where: {$0.id == postId})
        for x in postMatrix.indices {
            postMatrix[x].removeAll(where: {$0.id == postId})
        }
        print("removed")
    }
    
    func searchCities(_ recentCities: [City]) -> [City] {
        
        print(recentCities.map{$0.id})
        print(cityManager.allCities.map{$0.id}.prefix(10))
        
        let recentIDs = Set(recentCities.compactMap { $0.id })

        guard !citySearchText.isEmpty else {
            return cityManager.allCities.filter { !recentIDs.contains($0.id) }
        }
        
        allCitiesList = cityManager.allCities.filter {
            $0.city.lowercased().contains(citySearchText.lowercased()) ||
             $0.state_id.lowercased().contains(citySearchText.lowercased())
        }
        
        return allCitiesList
    }
    
    func loadInitialPostFeed(cityIds: [String]) async {
        reset()
        print("in initial feed func")
        await loadMorePostFeed(cityIds: cityIds)
    }
    
    func loadMorePostFeed(cityIds: [String]) async {
        print(isLoading, hasMore)
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer {isLoading = false; hasLoaded = true}
        do {
            print("CITIES: ", cityIds.prefix(3), cursor)
            let response = try await postManager.fetchHomeFeed(
                cityIds: cityIds,
                cursor: cursor
            )
            print("TRYING: ", response.posts.prefix(1))
            feedStore.loadedPosts.append(contentsOf: response.posts)
            cursor = response.nextCursor
            hasMore = response.nextCursor != nil
        } catch {
            print("Feed error:", error)
        }
    }
    
    func reset() {
        feedStore.loadedPosts.removeAll()
        postMatrix.removeAll()
        ingestedPostIDs.removeAll()
        print("RESET")
        cursor = nil
        hasMore = true
        hasLoaded = false
    }

//    
//    func fetchPostsIfNeeded(cities: [String]) async throws {
//        print("in home fetch")
//        guard !hasLoaded else {return}
//        guard feedStore.loadedPosts.isEmpty else {return}
//        isLoading = true
//        defer {isLoading = false}
//        do {
//            print("Doing home fetch")
//            let posts = try await postManager.getPosts(from: cities)
//    //        var posts = FirebasePostManager.shared.mockPosts
//            feedStore.loadedPosts = posts
//            hasLoaded = true
//        }
//        catch {
//            throw NetworkErrors.ErrorFetching
//        }
//    }
    
//    func fetchMorePosts(cities: [String]) async throws {
//        self.isLoading = true
//        defer {self.isLoading = false}
//        do {
//            let posts = try await postManager.getPosts(from: cities)
//            withAnimation(.easeInOut(duration: 0.3)) {
//                feedStore.loadedPosts = []
//            }
//            withAnimation(.easeInOut(duration: 0.3)) {
//                feedStore.loadedPosts = posts
//            }
//        }
//        catch {
//            throw NetworkErrors.ErrorFetching
//        }
//    }
    
    func fetchMorePostsNonAsync(cities: [String]) {
        Task {
            await loadInitialPostFeed(cityIds: cities)
        }
    }
    
    func fetchPost(postId: String) async throws -> PostModel {
        return try await postManager.getPost(id: postId)
    }
    
    func appendPostsToMatrix(posts: [PostModel], columns: Int) {
        if postMatrix.count == columns && postMatrix.isEmpty == false {
            var columnHeights = Array(repeating: 0, count: columns)
            for i in 0..<columns {
                let columnHeight = postMatrix[i].reduce(0) { $0 + Int($1.height) }
                columnHeights[i] = columnHeight
            }
            for post in posts {
                var p = post
                p.height = heights.randomElement() ?? 120
                
                // find shortest column
                if let minIndex = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) {
                    postMatrix[minIndex].append(p)
                    columnHeights[minIndex] += Int(p.height)
                }
            }
        } else {
            postMatrix = splitListSize(postlist: posts, columns: columns)
        }
    }
    
    private func updatePostsInMatrix(with posts: [PostModel]) {
        guard !posts.isEmpty else { return }
        // Create quick lookup
        let byId = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
        for colIndex in postMatrix.indices {
            for rowIndex in postMatrix[colIndex].indices {
                let current = postMatrix[colIndex][rowIndex]
                if var updated = byId[current.id] {
                    // Preserve layout height
                    updated.height = current.height
                    postMatrix[colIndex][rowIndex] = updated
                }
            }
        }
    }
    
    func splitListSize(postlist: [PostModel], columns: Int) -> [[PostModel]] {
        guard columns > 0 else { return [] }
        
        var postGrid: [[PostModel]] = Array(repeating: [], count: columns)
        var columnHeights: [Int] = Array(repeating: 0, count: columns)
        if !postMatrix.isEmpty {
            if postMatrix.count == columns {
                for i in 0..<columns {
                    let columnHeight = postMatrix[i].reduce(0) { $0 + Int($1.height) }
                    columnHeights[i] = columnHeight
                }
            }
        }
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
    
    func upvotePost(post: PostModel) {
        if let index = feedStore.loadedPosts.firstIndex(where: {$0.id == post.id}) {
            var post = feedStore.loadedPosts[index]
            post.upvotes += 1
            feedStore.loadedPosts[index] = post
        }
    }
    
    func removeUpvote(post: PostModel) {
        if let index = feedStore.loadedPosts.firstIndex(where: {$0.id == post.id}) {
            var post = feedStore.loadedPosts[index]
            post.upvotes -= 1
            feedStore.loadedPosts[index] = post
        }
    }
    
    func downvotePost(post: PostModel) {
        if let index = feedStore.loadedPosts.firstIndex(where: {$0.id == post.id}) {
            var post = feedStore.loadedPosts[index]
            post.downvotes += 1
            feedStore.loadedPosts[index] = post
        }
    }
    
    func removeDownvote(post: PostModel) {
        if let index = feedStore.loadedPosts.firstIndex(where: {$0.id == post.id}) {
            var post = feedStore.loadedPosts[index]
            post.downvotes -= 1
            feedStore.loadedPosts[index] = post
        }
    }
}

