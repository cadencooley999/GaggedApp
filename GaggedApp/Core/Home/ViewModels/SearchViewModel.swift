////
////  SearchViewModel.swift
////  GaggedApp
////
////  Created by Caden Cooley on 10/10/25.
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
    @Published var loadedPosts: [PostModel] = []
    @Published var loadedPolls: [PollWithOptions] = []
    @Published var globalPostMatrix: [[PostModel]] = []
    @Published var globalPollList: [PollWithOptions] = []
    @Published var columns: Int = 2
//    @Published var allPostsNearby: [PostModel] = []
//    @Published var firstPostsNearby: [PostModel] = []
//    @Published var allPollsNearby: [PollWithOptions] = []
//    @Published var firstPollsNearby: [PollWithOptions] = []
    @Published var selectedFilter: SearchFilter = .posts
    @Published var postsIsLoading: Bool = false
    @Published var pollsIsLoading: Bool = false
    @Published var hasMoreGlobalPosts: Bool = true
    @Published var hasMoreGlobalPolls: Bool = true
    @Published var hasLoadedPosts: Bool = false
    @Published var hasLoadedPolls: Bool = false


    // MARK: - Internals
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    private var postsCursor: ProperPostsCursor?
    private var pollsCursor: PollCursor?
    private var globalPostIds = Set<String>()
    private var globalPollIds = Set<String>()

    private let postManager = FirebasePostManager.shared
    private let pollManager = PollManager.shared

    private let heights: [CGFloat] = [220]
    
//    init() {
//        bindFeedStore()
//    }
//    
//    private func bindFeedStore() {
//        $loadedPosts
//            .sink { [weak self] posts in
//                self?.globalPostMatrix = self?.splitListSize(postlist: posts, columns: 2) ?? []
//            }
//            .store(in: &cancellables)
//        
//        $loadedPolls
//            .sink { [weak self] polls in
//                self?.globalPollList = polls
//            }
//            .store(in: &cancellables)
//    }
//    
    func appendPosts(posts: [PostModel]) {
        let filtered = posts.filter { globalPostIds.insert($0.id).inserted }
        withAnimation(.easeInOut(duration: 0.3)) {
            loadedPosts.append(contentsOf: filtered)
            print("appending")
            simpleAppend(posts: filtered, columns: columns)
        }
    }
    
    func appendPolls(polls: [PollWithOptions], animate: Bool = true) {
        let filtered = polls.filter { globalPollIds.insert($0.id).inserted }
        if animate {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadedPolls.append(contentsOf: filtered)
                globalPollList.append(contentsOf: filtered)
            }
        } else {
            loadedPolls.append(contentsOf: filtered)
            globalPollList.append(contentsOf: filtered)
        }
    }

    // MARK: - Subscribers
    func addSubscribers(blockedUserIds: [String] = []) {
        // Listen for search text changes
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                self.performSearchOrDefault(blockedUserIds: blockedUserIds)
            }
            .store(in: &cancellables)

        // Listen for filter changes
        $selectedFilter
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.performSearchOrDefault(blockedUserIds: blockedUserIds)
            }
            .store(in: &cancellables)
        
        // Trigger an initial load using the provided blockedUserIds
        performSearchOrDefault(blockedUserIds: blockedUserIds)
    }

    
    private func performSearchOrDefault(blockedUserIds: [String]) {
        guard hasOnboarded, isLoggedIn else { return }

        searchTask?.cancel()

        searchTask = Task { @MainActor in

            do {
                if searchText.isEmpty {
                    try await handleEmptySearch(blockedUserIds: blockedUserIds)
                } else {
                    try await handleSearch(text: searchText, blockedUserIds: blockedUserIds)
                }
            } catch {
                print("error with searchTask")
            }
        }
    }
    
    func loadInitialGlobalPosts(blockedUserIds: [String]) async throws {
        resetGlobalPosts()
        try await loadGlobalPosts(blockedUserIds: blockedUserIds)
        hasLoadedPosts = true
    }
    
    func loadGlobalPosts(blockedUserIds: [String]) async throws {
        guard hasMoreGlobalPosts else {return}
        postsIsLoading = true
        defer { postsIsLoading = false }
        let response = try await postManager.fetchGlobalFeed(blockedUserIds: blockedUserIds, cursor: postsCursor)
        appendPosts(posts: response.0)
        postsCursor = response.1
        hasMoreGlobalPosts = response.1 != nil
    }
    
    func resetGlobalPosts() {
        loadedPosts.removeAll()
        globalPostIds.removeAll()
        globalPostMatrix.removeAll()
        postsCursor = nil
        hasMoreGlobalPosts = true
        hasLoadedPosts = false
    }
    
    func loadInitialGlobalPolls(blockedUserIds: [String]) async throws {
        resetGlobalPolls()
        try await loadGlobalPolls(animate: false, blockedUserIds: blockedUserIds)
        hasLoadedPolls = true
    }
    
    func loadGlobalPolls(animate: Bool = true, blockedUserIds: [String]) async throws {
        guard hasMoreGlobalPolls else {return}
        pollsIsLoading = true
        defer { pollsIsLoading = false }
        let response = try await pollManager.fetchGlobalPollFeed(pageSize: 15, blockedUserIds: blockedUserIds, cursor: pollsCursor)
        appendPolls(polls: response.0, animate: animate)
        pollsCursor = response.1
        hasMoreGlobalPolls = response.1 != nil
    }
    
    func resetGlobalPolls() {
        loadedPolls.removeAll()
        globalPollIds.removeAll()
        globalPollList.removeAll()
        pollsCursor = nil
        hasMoreGlobalPolls = true
        hasLoadedPolls = false
    }

    // MARK: - Empty Search
    
    private func handleEmptySearch(blockedUserIds: [String]) async throws {
        if selectedFilter == .posts {
            if loadedPosts.isEmpty {
                try await loadInitialGlobalPosts(blockedUserIds: blockedUserIds)
            }
            print("resetting")
            globalPostMatrix = simpleSplit(
                posts: loadedPosts,
                columns: columns
            )
        } else {
            if loadedPolls.isEmpty {
                try await loadInitialGlobalPolls(blockedUserIds: blockedUserIds)
            }
            globalPollList = loadedPolls
        }
    }

    // MARK: - Active Search
    private func handleSearch(text: String, blockedUserIds: [String]) async throws {
        defer { postsIsLoading = false; pollsIsLoading = false}
        if selectedFilter == .posts {
            postsIsLoading = true
            let result = try await postManager.getGlobalPostsFromSearch(keyword: text, blockedUserIds: blockedUserIds)
            globalPostMatrix = simpleSplit(posts: result, columns: columns)
        } else {
            pollsIsLoading = true
            let result = try await pollManager.getGlobalPollsFromSearch(keyword: text, blockedUserIds: blockedUserIds)
            globalPollList = result
        }
    }
    
    func handlePollsRefresh(blockedUserIds: [String]) async throws {
        if searchText.isEmpty {
            try await loadInitialGlobalPolls(blockedUserIds: blockedUserIds)
        }
        if !searchText.isEmpty {
            try await handleSearch(text: searchText, blockedUserIds: blockedUserIds)
        }
        PollCache.shared.clearCache()
    }
    
    func handlePostsRefresh(blockedUserIds: [String]) async throws {
        if searchText.isEmpty {
            try await loadInitialGlobalPosts(blockedUserIds: blockedUserIds)
        }
        if !searchText.isEmpty {
            try await handleSearch(text: searchText, blockedUserIds: blockedUserIds)
        }
    }

    // MARK: - Layout
    func simpleSplit(posts: [PostModel], columns: Int) -> [[PostModel]]{
        var grid: [[PostModel]] = Array(repeating: [], count: columns)
        for post in posts {
            if let minIndex = grid.indices.min(by: { grid[$0].count < grid[$1].count }) {
                grid[minIndex].append(post)
            }
            else {
                grid[0].append(post)
            }
        }
        return grid
    }
    
    func simpleAppend(posts: [PostModel], columns: Int) {
        if globalPostMatrix.isEmpty {
            globalPostMatrix = Array(repeating: [], count: columns)
        }
        for post in posts {
            if let minIndex = globalPostMatrix.indices.min(by: { globalPostMatrix[$0].count < globalPostMatrix[$1].count }) {
                globalPostMatrix[minIndex].append(post)
            }
            else {
                globalPostMatrix[0].append(post)
            }
        }
    }
    
    func appendPostsToMatrix(posts: [PostModel], columns: Int) {
        if globalPostMatrix.count == columns && globalPostMatrix.isEmpty == false {
            var columnHeights = Array(repeating: 0, count: columns)
            for i in 0..<columns {
                let columnHeight = globalPostMatrix[i].reduce(0) { $0 + Int($1.height) }
                columnHeights[i] = columnHeight
            }
            for post in posts {
                var p = post
                p.height = heights.randomElement() ?? 120
                
                // find shortest column
                if let minIndex = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) {
                    globalPostMatrix[minIndex].append(p)
                    columnHeights[minIndex] += Int(p.height)
                }
            }
        } else {
            globalPostMatrix = splitListSize(postlist: posts, columns: columns)
        }
    }
    
    func splitListSize(postlist: [PostModel], columns: Int) -> [[PostModel]] {
        guard columns > 0 else { return [] }
        
        var postGrid: [[PostModel]] = Array(repeating: [], count: columns)
        var columnHeights: [Int] = Array(repeating: 0, count: columns)
        if !globalPostMatrix.isEmpty {
            if globalPostMatrix.count == columns {
                for i in 0..<columns {
                    let columnHeight = globalPostMatrix[i].reduce(0) { $0 + Int($1.height) }
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
    
    func savedLoadOptions(for pollId: String) async throws {
        var options: [PollOption] = []
        if let cachedOptions = PollCache.shared.digPollOptions(pollId: pollId) {
            print("getting from cache")
            options = cachedOptions
        }
        else {
            print("Gettting from network")
            options = try await pollManager.fetchPollOptions(pollId: pollId)
            PollCache.shared.cacheOptions(pollId: pollId, options: options)
        }
        if let idx = globalPollList.firstIndex(where: {$0.id == pollId}) {
            var newPoll = globalPollList[idx]
            newPoll.options = options
            withAnimation(.easeInOut(duration: 0.3)) {
                globalPollList[idx] = newPoll
            }
        }
    }
    
    @MainActor
    func loadOptions(for pollId: String) async throws {
        var options: [PollOption] = []
        if let cachedOptions = PollCache.shared.digPollOptions(pollId: pollId) {
            print("getting from cache")
            options = cachedOptions
        }
        else {
            print("Gettting from network")
            options = try await pollManager.fetchPollOptions(pollId: pollId)
            PollCache.shared.cacheOptions(pollId: pollId, options: options)
        }
        if let idx = globalPollList.firstIndex(where: {$0.id == pollId}) {
            print("found index")
            var newPoll = globalPollList[idx]
            newPoll.options = options
            withAnimation(.easeInOut(duration: 0.3)) {
                globalPollList[idx] = newPoll
            }
        }
    }
    
    func clearOptions(for pollId: String) {
        if let idx = globalPollList.firstIndex(where: {$0.id == pollId}) {
            var newPoll = globalPollList[idx]
            newPoll.options = []
            withAnimation(.easeInOut(duration: 0.3)) {
                globalPollList[idx] = newPoll
            }
        }
    }
    
    func refreshFeedPoll(pollId: String, optionToAdd: String, optionToSubtract: String) {
        if let index = globalPollList.firstIndex(where: {$0.id == pollId}) {
            var poll = globalPollList[index]
            if optionToAdd != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToAdd}) {
                    print("added")
                    poll.options[optionIdx].voteCount += 1
                    poll.poll.totalVotes += 1
                }
            }
            if optionToSubtract != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToSubtract}) {
                    print("subtracted")
                    poll.options[optionIdx].voteCount -= 1
                    poll.poll.totalVotes -= 1
                }
            }
            PollCache.shared.cacheOptions(pollId: poll.id, options: poll.options)
            globalPollList[index] = poll
            if let idx = loadedPolls.firstIndex(where: {$0.id == pollId}) {
                print("found loadedPolls indx")
                loadedPolls[idx] = poll
            }
        }
    }
}

