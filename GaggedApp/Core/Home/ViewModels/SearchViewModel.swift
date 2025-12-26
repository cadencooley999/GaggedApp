////
////  SearchViewModel.swift
////  GaggedApp
////
////  Created by Caden Cooley on 10/10/25.
////
//
import Foundation
import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - App State
    @AppStorage("hasOnboarded") var hasOnboarded = false
    @AppStorage("isLoggedIn") var isLoggedIn = false

    // MARK: - Published State
    @Published var searchText: String = ""
    @Published var postMatrix: [[PostModel]] = []
    @Published var pollList: [PollWithOptions] = []
    @Published var columns: Int = 2
//    @Published var allPostsNearby: [PostModel] = []
//    @Published var firstPostsNearby: [PostModel] = []
//    @Published var allPollsNearby: [PollWithOptions] = []
//    @Published var firstPollsNearby: [PollWithOptions] = []
    @Published var selectedFilter: SearchFilter = .posts
    @Published var isLoading: Bool = false

    // MARK: - Internals
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    private let postManager = FirebasePostManager.shared
    private let pollManager = PollManager.shared

    private let heights: [CGFloat] = [220]
    
    private let feedStore: FeedStore

    init(feedStore: FeedStore) {
        self.feedStore = feedStore
        bindFeedStore()
    }
    
    private func bindFeedStore() {
        feedStore.$loadedPosts
            .sink { [weak self] posts in
                self?.postMatrix = self?.splitListSize(postlist: posts, columns: 2) ?? []
            }
            .store(in: &cancellables)
        
        feedStore.$loadedPolls
            .sink { [weak self] polls in
                self?.pollList = polls
            }
            .store(in: &cancellables)
    }

    // MARK: - Subscribers
    func addSubscribers(cityIDsProvider: @escaping () -> [String]) {
        // Listen for search text changes
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.performSearchOrDefault(cityIDsProvider: cityIDsProvider)
            }
            .store(in: &cancellables)

        // Listen for filter changes
        $selectedFilter
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.performSearchOrDefault(cityIDsProvider: cityIDsProvider)
            }
            .store(in: &cancellables)
    }

    
    private func performSearchOrDefault(cityIDsProvider: @escaping () -> [String]) {
        guard hasOnboarded, isLoggedIn else { return }

        searchTask?.cancel()

        searchTask = Task { @MainActor in
            let cityIDs = cityIDsProvider()

            if searchText.isEmpty {
                await handleEmptySearch(cities: cityIDs)
            } else {
                await handleSearch(text: searchText, cities: cityIDs)
            }

            isLoading = false
        }
    }


    // MARK: - Empty Search
    private func handleEmptySearch(cities: [String]) async {
        if selectedFilter == .posts {
            if feedStore.loadedPosts.isEmpty {
                isLoading = true
                do {
                    let posts = try await postManager.getPosts(from: cities)
                    feedStore.loadedPosts = posts
                } catch {
                    return
                }
            }
            else {
                postMatrix = splitListSize(
                    postlist: feedStore.loadedPosts,
                    columns: columns
                )
            }

        } else {
            if feedStore.loadedPolls.isEmpty {
                isLoading = true
                do {
                    let polls = try await pollManager.fetchPolls(cityIds: cities)
                    feedStore.loadedPolls = polls
                } catch {
                    return
                }
            }
            else {
                pollList = feedStore.loadedPolls
            }
        }
    }

    // MARK: - Active Search
    private func handleSearch(text: String, cities: [String]) async {
        if selectedFilter == .posts {
            if feedStore.allPostsTriggered == false {
                do {
                    let allPostsNearby = try await postManager.getAllPostsNearby(cities: cities)
                    feedStore.loadedPosts = allPostsNearby
                    feedStore.allPostsTriggered = true
                } catch {
                    return
                }
            }

            let posts = postManager.getPostsFromSearch(
                keyword: text,
                allPostsNearby: feedStore.loadedPosts
            )

            postMatrix = splitListSize(
                postlist: posts,
                columns: columns
            )

        } else {
            if feedStore.allPollsTriggered == false {
                do {
                    let allPollsNearby = try await pollManager.fetchAllPollsNearby(cityIds: cities)
                    feedStore.loadedPolls = allPollsNearby
                    feedStore.allPollsTriggered = true
                } catch {
                    return
                }
            }

            pollList = pollManager.getPollsFromSearch(
                keyword: text,
                allPollsNearby: feedStore.loadedPolls
            )
        }
    }

    // MARK: - Layout
    private func splitListSize(
        postlist: [PostModel],
        columns: Int
    ) -> [[PostModel]] {

        guard columns > 0 else { return [] }

        var grid: [[PostModel]] = Array(repeating: [], count: columns)
        var columnHeights = Array(repeating: 0, count: columns)

        for post in postlist {
            var p = post
            p.height = heights.randomElement() ?? 120

            if let minIndex = columnHeights.indices.min(
                by: { columnHeights[$0] < columnHeights[$1] }
            ) {
                grid[minIndex].append(p)
                columnHeights[minIndex] += Int(p.height)
            }
        }

        return grid
    }
}
