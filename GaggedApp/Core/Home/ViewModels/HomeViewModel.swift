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
    
    @Published var hasLoaded = false
    @Published var allCitiesList: [City] = []
    @Published var citySearchText: String = ""
    @Published var postMatrix: [[PostModel]] = []
    @Published var columns: Int = 2
    @Published var isLoading: Bool = false
    
    let storageManager = StorageManager.shared
    let postManager = FirebasePostManager.shared
    let cityManager = CityManager.shared
    
    let heights: [CGFloat] = [240, 200, 300]
    
    var cancellables: Set<AnyCancellable> = []
    
    func addSubscribers(_ recentCities: [City]) {
        $citySearchText
            .debounce(for: 0.05, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                allCitiesList = searchCities(recentCities)
            }
            .store(in: &cancellables)
            
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
    
    func fetchPostsIfNeeded(cities: [String]) async throws {
        guard !hasLoaded else {return}
        let posts = try await postManager.getPosts(from: cities)
//        var posts = FirebasePostManager.shared.mockPosts
        let postLists = splitListSize(postlist: posts, columns: columns)
        postMatrix = postLists
        hasLoaded = true
    }
    
    func fetchMorePosts(cities: [String]) async throws {
        withAnimation(.easeInOut(duration: 0.3)) {
            postMatrix = []
        }
        self.isLoading = true
        let posts = try await postManager.getPosts(from: cities)
//        var posts = FirebasePostManager.shared.mockPosts
        let postLists = splitListSize(postlist: posts, columns: columns)
        print("fetching more posts")
        withAnimation(.easeInOut(duration: 0.3)) {
            postMatrix = postLists
        }
        self.isLoading = false
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
    
    func upvotePost(post: PostModel) {
        for i in postMatrix.indices {
            if let index = postMatrix[i].firstIndex(where: {$0.id == post.id}) {
                var row = postMatrix[i][index]
                print("in the row")
                row.upvotes += 1
                postMatrix[i][index] = row
            }
        }
    }
    
    func removeUpvote(post: PostModel) {
        for i in postMatrix.indices {
            if let index = postMatrix[i].firstIndex(where: {$0.id == post.id}) {
                var row = postMatrix[i][index]
                print("in the row")
                row.upvotes -= 1
                postMatrix[i][index] = row
            }
        }
    }
    
    func downvotePost(post: PostModel) {
        for i in postMatrix.indices {
            if let index = postMatrix[i].firstIndex(where: {$0.id == post.id}) {
                var row = postMatrix[i][index]
                row.downvotes += 1
                postMatrix[i][index] = row
            }
        }
    }
    
    func removeDownvote(post: PostModel) {
        for i in postMatrix.indices {
            if let index = postMatrix[i].firstIndex(where: {$0.id == post.id}) {
                var row = postMatrix[i][index]
                row.downvotes -= 1
                postMatrix[i][index] = row
            }
        }
    }
    
    @MainActor
    func testUpload() async {
        do {
            let testImage = UIImage(systemName: "person.circle")! // any SF Symbol
            let downloadURL = try await storageManager.uploadImage(testImage, imageId: UUID().uuidString)
            print("✅ Image uploaded! URL: \(downloadURL)")
        } catch {
            print("❌ Upload failed: \(error)")
        }
    }
}

extension HomeViewModel {
    static func previewModel() -> HomeViewModel {
        let vm = HomeViewModel()
        let fakePosts: [PostModel] = FirebasePostManager.shared.mockPosts
        vm.postMatrix = vm.splitListSize(postlist: fakePosts, columns: 2)
        return vm
    }
}
