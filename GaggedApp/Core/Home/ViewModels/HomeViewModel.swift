//
//  HomeViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var hasLoaded = false
    
    @Published var postMatrix: [[PostModel]] = []
    @Published var columns: Int = 2
    @Published var isLoading: Bool = false
    
    let storageManager = StorageManager.shared
    let postManager = FirebasePostManager.shared
    
    let heights: [CGFloat] = [240, 200, 300]
    
    func fetchPostsIfNeeded() async throws {
        guard !hasLoaded else {return}
        let posts = try await postManager.getPosts()
//        var posts = FirebasePostManager.shared.mockPosts
        let postLists = splitListSize(postlist: posts, columns: columns)
        postMatrix = postLists
        hasLoaded = true
    }
    
    func fetchMorePosts() async throws {
        let posts = try await postManager.getPosts()
//        var posts = FirebasePostManager.shared.mockPosts
        let postLists = splitListSize(postlist: posts, columns: columns)
        postMatrix = postLists
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
                postMatrix[i][index].upvotes += 1
            }
        }
    }
    
    func downvotePost(post: PostModel) {
        for i in postMatrix.indices {
            if let index = postMatrix[i].firstIndex(where: {$0.id == post.id}) {
                postMatrix[i][index].upvotes += 1
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
