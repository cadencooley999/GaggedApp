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

// Cursor aliases for other sections to mirror UserPostsCursor
// Assumes managers expose the same cursor shape

struct ProfPicParams {
    let offsetX: CGFloat
    let offsetY: CGFloat
    let scale: CGFloat
}

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("isAdmin") var isAdmin = false
    
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
    @Published var loadedUser: UserModel = UserModel(id: "", username: "", garma: 0, imageAddress: "", createdAt: Timestamp(date: Date()), isAdmin: false, numPosts: 0, keywords: [])
    @Published var hasMoreUserPosts: Bool = true
    @Published var hasMoreUserComments: Bool = true
    @Published var hasMoreUserPolls: Bool = true
    @Published var hasMoreUpvotedPosts: Bool = true
    
    private var userPostsCursor: ProperPostsCursor? = nil
    private var userCommentsCursor: CommentsCursor? = nil
    private var userPollsCursor: PollCursor? = nil
    private var upvotedPostsCursor: Date? = nil
    
    private var upvotedDebounceTask: Task<Void, Never>? = nil
    private var postsDebounceTask: Task<Void, Never>? = nil
    private var commentsDebounceTask: Task<Void, Never>? = nil
    private var pollsDebounceTask: Task<Void, Never>? = nil
    
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
            var user = try await userManager.fetchUser(userId: userId)
            if user.numPosts < 0 {
                try await userManager.addPostToUser(userId: userId)
                user.numPosts = 0
            }
            loadedUser = user
            isAdmin = loadedUser.isAdmin
            print("IMAGE URL", user.imageAddress)
        }
    }
    
    func loadUserInfoIfNeeded() async throws {
        guard loadedUser.id == "" else { return }
        Task {
            let user = try await userManager.fetchUser(userId: userId)
            loadedUser = user
            isAdmin = loadedUser.isAdmin
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
    
    func loadInitialUserPosts() async {
        hasLoadedPosts = false
        resetUserPosts()
        await getUserPosts()
    }
    
    func resetUserPosts() {
        userPosts.removeAll()
        userPostsCursor = nil
        hasMoreUserPosts = true
        hasLoadedPosts = false
    }
    
    func getUserPosts() async {
        print("in, ", hasMoreUserPosts)
        guard !userId.isEmpty, hasMoreUserPosts else { return }

        hasLoadedPosts = false

        do {
            let (posts, nextCursor) = try await postManager.getUserPosts(uid: userId, cursor: userPostsCursor)

            // Cancel any pending UI update
            postsDebounceTask?.cancel()

            postsDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.userPosts.append(contentsOf: posts)
                }

                self.userPostsCursor = nextCursor
                self.hasMoreUserPosts = nextCursor != nil
                self.hasLoadedPosts = true
            }

        } catch {
            print("feed error", error)
            hasLoadedPosts = true
        }
    }
    
    // MARK: - Comments (pagination)
    func loadInitialUserComments() async {
        hasLoadedComments
        resetUserComments()
        await getUserComments()
    }

    func resetUserComments() {
        userComments.removeAll()
        userCommentsCursor = nil
        hasMoreUserComments = true
        hasLoadedComments = false
    }

    func getUserComments() async {
        print("comments in, ", hasMoreUserComments)
        guard !userId.isEmpty, hasMoreUserComments else { return }

        hasLoadedComments = false

        do {
            let (comments, nextCursor) = try await commentsManager.getUserComments(userId: userId, cursor: userCommentsCursor)

            // Cancel any pending UI update
            commentsDebounceTask?.cancel()

            commentsDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.userComments.append(contentsOf: comments)
                }

                self.userCommentsCursor = nextCursor
                self.hasMoreUserComments = nextCursor != nil
                self.hasLoadedComments = true
            }

        } catch {
            print("comments error", error)
            hasLoadedComments = true
        }
    }
    
    // MARK: - Polls (pagination)
    func loadInitialUserPolls() async {
        hasLoadedPolls = false
        resetUserPolls()
        await getUserPolls()
    }

    func resetUserPolls() {
        userPolls.removeAll()
        userPollsCursor = nil
        hasMoreUserPolls = true
        hasLoadedPolls = false
    }

    func getUserPolls() async {
        print("polls in, ", hasMoreUserPolls)
        guard !userId.isEmpty, hasMoreUserPolls else { return }

        hasLoadedPolls = false

        do {
            let (polls, nextCursor) = try await pollManager.getUserPolls(uid: userId, cursor: userPollsCursor)

            // Cancel any pending UI update
            pollsDebounceTask?.cancel()

            pollsDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.userPolls.append(contentsOf: polls)
                }

                self.userPollsCursor = nextCursor
                self.hasMoreUserPolls = nextCursor != nil
                self.hasLoadedPolls = true
            }

        } catch {
            print("polls error", error)
            hasLoadedPolls = true
        }
    }
    
    // MARK: - Upvoted (pagination)
    func loadInitialUpvotedPosts() async {
        hasLoadedUpvoted = false
        resetUpvotedPosts()
        await getUpvotedPosts()
    }

    func resetUpvotedPosts() {
        upvotedPosts.removeAll()
        upvotedPostsCursor = nil
        hasMoreUpvotedPosts = true
        hasLoadedUpvoted = false
    }

    func getUpvotedPosts() async {
        guard !userId.isEmpty, hasMoreUpvotedPosts else { return }

        hasLoadedUpvoted = false

        do {
            let (posts, nextCursor) =
                try await postManager.getUpvotedPostsFromCoreData(
                    cursor: upvotedPostsCursor
                )

            // Cancel any pending UI update
            upvotedDebounceTask?.cancel()

            upvotedDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.upvotedPosts.append(contentsOf: posts)
                }

                self.upvotedPostsCursor = nextCursor
                self.hasMoreUpvotedPosts = nextCursor != nil
                self.hasLoadedUpvoted = true
            }

        } catch {
            print("upvoted error", error)
            hasLoadedUpvoted = true
        }
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
        if let idx = savedPolls.firstIndex(where: {$0.id == pollId}) {
            var newPoll = savedPolls[idx]
            newPoll.options = options
            withAnimation(.easeInOut(duration: 0.3)) {
                savedPolls[idx] = newPoll
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
        if let idx = userPolls.firstIndex(where: {$0.id == pollId}) {
            print("found index")
            var newPoll = userPolls[idx]
            print("options: \(options)")
            newPoll.options = options
            withAnimation(.easeInOut(duration: 0.3)) {
                userPolls[idx] = newPoll
            }
        }
    }
    
    func clearOptions(for pollId: String) {
        if let idx = userPolls.firstIndex(where: {$0.id == pollId}) {
            var newPoll = userPolls[idx]
            newPoll.options = []
            withAnimation(.easeInOut(duration: 0.3)) {
                userPolls[idx] = newPoll
            }
        }
    }
    func savedClearOptions(for pollId: String) {
        if let idx = savedPolls.firstIndex(where: {$0.id == pollId}) {
            var newPoll = savedPolls[idx]
            newPoll.options = []
            withAnimation(.easeInOut(duration: 0.3)) {
                savedPolls[idx] = newPoll
            }
        }
    }
    
    func refreshFeedPoll(pollId: String, optionToAdd: String, optionToSubtract: String) {
        if let index = userPolls.firstIndex(where: {$0.id == pollId}) {
            var poll = userPolls[index]
            if optionToAdd != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToAdd}) {
                    print("Changed option", optionIdx)
                    poll.options[optionIdx].voteCount += 1
                    poll.poll.totalVotes += 1
                }
            }
            if optionToSubtract != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToSubtract}) {
                    poll.options[optionIdx].voteCount -= 1
                    poll.poll.totalVotes -= 1
                }
            }
            PollCache.shared.cacheOptions(pollId: poll.id, options: poll.options)
            userPolls[index] = poll
            if let idx = userPolls.firstIndex(where: {$0.id == pollId}) {
                userPolls[idx] = poll
            }
        }
    }
    
    func refreshSavedFeedPoll(pollId: String, optionToAdd: String, optionToSubtract: String) {
        if let index = savedPolls.firstIndex(where: {$0.id == pollId}) {
            var poll = savedPolls[index]
            if optionToAdd != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToAdd}) {
                    print("Changed option", optionIdx)
                    poll.options[optionIdx].voteCount += 1
                    poll.poll.totalVotes += 1
                }
            }
            if optionToSubtract != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToSubtract}) {
                    poll.options[optionIdx].voteCount -= 1
                    poll.poll.totalVotes -= 1
                }
            }
            PollCache.shared.cacheOptions(pollId: poll.id, options: poll.options)
            savedPolls[index] = poll
            if let idx = savedPolls.firstIndex(where: {$0.id == pollId}) {
                savedPolls[idx] = poll
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
        hasLoadedSaved = false
        try await getSavedPosts()
        PollCache.shared.clearCache()
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
        PollCache.shared.clearCache()
        loadedUser = UserModel(id: "", username: "", garma: 0, imageAddress: "", createdAt: Timestamp(date: Date()), isAdmin: false, numPosts: 0, keywords: [])
    }
}

