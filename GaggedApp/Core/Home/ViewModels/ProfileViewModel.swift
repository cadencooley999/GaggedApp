//
//  ProfileViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/7/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

struct ProfPicParams {
    let offsetX: CGFloat
    let offsetY: CGFloat
    let scale: CGFloat
}

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    
    @Published var hasLoadedPosts = false
    @Published var hasLoadedComments = false
    @Published var hasLoadedPolls = false
    @Published var hasLoadedUpvoted = false
    @Published var hasLoadedSaved = false
    @Published var profPicParams: ProfPicParams? = nil
    @Published var post: PostModel? = nil
    @Published var userPosts: [PostModel] = []
    @Published var userComments: [CommentModel] = []
    @Published var userPolls: [PollWithOptions] = []
    @Published var upvotedPosts: [PostModel] = []
    @Published var savedPosts: [PostModel] = []
    @Published var savedPolls: [PollWithOptions] = []
    @Published var searchText: String = ""
    @Published var searchResults: [MixedType] = []
    @Published var loadedUser: UserModel = UserModel(id: "", username: "", garma: 0, imageAddress: "", createdAt: Timestamp(date: Date()), keywords: [])
    
    let postManager = FirebasePostManager.shared
    let commentsManager = CommentsManager.shared
    let eventsManager = EventManager.shared
    let eventManager = EventManager.shared
    let userManager = UserManager.shared
    let storageManager = StorageManager.shared
    let pollManager = PollManager.shared
    
    var cancellables = Set<AnyCancellable>()
    
//    init() {
//        addSubscribers()
//    }
    
//    func addSubscribers() {
//        $searchText
//            .debounce(for: 0.5, scheduler: DispatchQueue.main)
//            .sink { _ in
//                if self.searchText == "" {
//                    Task {
//                        self.getSearchedPosts()
//                    }
//                }
//                else {
//                    self.searchUserPosts()
//                }
//            }
//            .store(in: &cancellables)
//    }
    
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
    
    func setNewProfileImage(address: String) async throws {
        try await userManager.setNewProfileImage(address: address)
    }
    
    func loadMoreUserInfo() async throws {
        Task {
            let user = try await userManager.fetchUser(userId: userId)
            loadedUser = user
            print("IMAGE URL", user.imageAddress)
        }
    }
    
    func loadUserInfoIfNeeded() async throws {
        guard loadedUser.id == "" else { return }
        Task {
            let user = try await userManager.fetchUser(userId: userId)
            loadedUser = user
            print("IMAGE URL", user.imageAddress)
        }
    }
    
//    func getSearchedPosts() {
//        print("getting searched posts")
//        searchResults = mixAndOrder(postList: savedPosts, eventList: savedEvents)
//    }
    
//    func searchUserPosts() {
//        let searchKeyword = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
//        print("Searching for: \(searchKeyword)")
//        
//        let searchedPosts = savedPosts.filter { post in
//            post.keywords.contains { keyword in
//                keyword.lowercased().contains(searchKeyword)
//            }
//        }
//        
//        let searchedEvents = savedEvents.filter { event in
//            event.keywords.contains { keyword in
//                keyword.lowercased().contains(searchKeyword)
//            }
//        }
//        
//        searchResults = mixAndOrder(postList: searchedPosts, eventList: searchedEvents)
//    }
    
    func getUserPostsIfNeeded() async throws {
        guard !hasLoadedPosts else {return}
        let posts = try await postManager.getUserPosts(uid: userId)
        userPosts = posts
        hasLoadedPosts = true
    }
    
    func getMoreUserPosts() async throws {
        let posts = try await postManager.getUserPosts(uid: userId)
        userPosts = posts
    }
    
    func getCommentsIfNeeded() async throws {
        guard !hasLoadedComments else {return}
        let comments = try await commentsManager.getUserComments(userId: userId)
        userComments = comments
        hasLoadedComments = true
    }
    
    func getMoreUserComments() async throws {
        let comments = try await commentsManager.getUserComments(userId: userId)
        userComments = comments
    }
    
    func getUserPollsIfNeeded() async throws {
        guard !hasLoadedPolls else {return}
        let polls = try await pollManager.getUserPolls(uid: userId)
        userPolls = polls
        hasLoadedPolls = true
    }
    
    func getMoreUserPolls() async throws {
        let polls = try await pollManager.getUserPolls(uid: userId)
        userPolls = polls
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
        if let idx = savedPolls.firstIndex(where: {$0.poll.id == pollId}) {
            var newPoll = savedPolls[idx]
            newPoll.options = options
            withAnimation(.easeInOut(duration: 0.3)) {
                savedPolls[idx] = newPoll
            }
        }
    }
    
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
        if let idx = userPolls.firstIndex(where: {$0.poll.id == pollId}) {
            var newPoll = userPolls[idx]
            newPoll.options = options
            withAnimation(.easeInOut(duration: 0.3)) {
                userPolls[idx] = newPoll
            }
        }
    }
    
    func clearOptions(for pollId: String) {
        if let idx = userPolls.firstIndex(where: {$0.poll.id == pollId}) {
            var newPoll = userPolls[idx]
            newPoll.options = []
            withAnimation(.easeInOut(duration: 0.3)) {
                userPolls[idx] = newPoll
            }
        }
    }
    func savedClearOptions(for pollId: String) {
        if let idx = savedPolls.firstIndex(where: {$0.poll.id == pollId}) {
            var newPoll = savedPolls[idx]
            newPoll.options = []
            withAnimation(.easeInOut(duration: 0.3)) {
                savedPolls[idx] = newPoll
            }
        }
    }
    
    func getMoreUpvotedPosts() {
        Task {
            let posts = try await postManager.getUpvotedPostFromCoreData()
            upvotedPosts = posts
            hasLoadedUpvoted = true
        }
    }
    
    func getUpvotedPostsIfNeeded() {
        if !hasLoadedUpvoted {
            Task {
                let posts = try await postManager.getUpvotedPostFromCoreData()
                upvotedPosts = posts
                hasLoadedUpvoted = true
            }
        }
    }
    
    func formatFirestoreDate(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
    
    @MainActor
    func getSavedPosts() async throws {
        print("Getting Saved Posts ")
        let posts = CoreDataManager.shared.getSavedPosts()
        savedPosts = try await postManager.getPostsFromIds(ids: posts.map({$0.id ?? ""}))
    }
    
    @MainActor
    func getSavedPolls() async throws {
        let polls = CoreDataManager.shared.getSavedPolls()
        print(polls)
        savedPolls = try await pollManager.getPollsFromIds(ids: polls.map({$0.id ?? ""}))
    }
    
    @MainActor
    func loadSavedIfNeeded() async throws {
        if !hasLoadedSaved {
            try await getSavedPosts()
            try await getSavedPolls()
            hasLoadedSaved = true
        }
    }
    
    @MainActor
    func refreshSaved() async throws {
        try await getSavedPosts()
        try await getSavedPolls()
        hasLoadedSaved = true
    }
    
    func clearStates() {
        hasLoadedPosts = false
        hasLoadedComments = false
        hasLoadedPolls = false
        hasLoadedUpvoted = false
        hasLoadedSaved = false
        profPicParams = nil
        post = nil
        userPosts = []
        userComments = []
        userPolls = []
        upvotedPosts = []
        savedPosts = []
        savedPolls = []
        searchText = ""
        searchResults = []
        loadedUser = UserModel(id: "", username: "", garma: 0, imageAddress: "", createdAt: Timestamp(date: Date()), keywords: [])
    }
}
