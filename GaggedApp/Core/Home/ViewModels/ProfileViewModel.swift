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
    @AppStorage("profImageUrl") var profImageUrl = ""
    
    @Published var hasLoadedPosts = false
    @Published var hasLoadedComments = false
    @Published var hasLoadedEvents = false
    @Published var profPicParams: ProfPicParams? = nil
    @Published var post: PostModel? = nil
    @Published var userPosts: [PostModel] = []
    @Published var userComments: [CommentModel] = []
    @Published var userEvents: [EventModel] = []
    @Published var upvotedPosts: [PostModel] = []
    @Published var sectionLoading: String = ""
    @Published var savedPosts: [PostModel] = []
    @Published var savedEvents: [EventModel] = []
    @Published var searchText: String = ""
    @Published var searchResults: [MixedType] = []
    @Published var loadedUser: UserModel = UserModel(id: "", username: "", garma: 0, imageAddress: "", createdAt: Timestamp(date: Date()), keywords: [])
    
    let postManager = FirebasePostManager.shared
    let commentsManager = CommentsManager.shared
    let eventsManager = EventManager.shared
    let coreDataManager = CoreDataManager.shared
    let eventManager = EventManager.shared
    let userManager = UserManager.shared
    let storageManager = StorageManager.shared
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        addSubscribers()
    }
    
    func addSubscribers() {
        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                if self.searchText == "" {
                    Task {
                        self.getSearchedPosts()
                    }
                }
                else {
                    self.searchUserPosts()
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
    
    func setNewProfileImage(address: String) async throws {
        try await userManager.setNewProfileImage(address: address)
    }
    
    func loadUserInfo() async throws {
        Task {
            let user = try await userManager.fetchUser(userId: userId)
            loadedUser = user
            print("IMAGE URL", user.imageAddress)
        }
    }
    
    func getSearchedPosts() {
        print("getting searched posts")
        searchResults = mixAndOrder(postList: savedPosts, eventList: savedEvents)
    }
    
    func searchUserPosts() {
        let searchKeyword = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("Searching for: \(searchKeyword)")
        
        let searchedPosts = savedPosts.filter { post in
            post.keywords.contains { keyword in
                keyword.lowercased().contains(searchKeyword)
            }
        }
        
        let searchedEvents = savedEvents.filter { event in
            event.keywords.contains { keyword in
                keyword.lowercased().contains(searchKeyword)
            }
        }
        
        searchResults = mixAndOrder(postList: searchedPosts, eventList: searchedEvents)
    }
    
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
    
    func getUserEventsIfNeeded() async throws {
        guard !hasLoadedEvents else {return}
        let events = try await eventsManager.getUserEvents(uid: userId)
        userEvents = events
        hasLoadedEvents = true
    }
    
    func getMoreUserEvents() async throws {
        let events = try await eventsManager.getUserEvents(uid: userId)
        userEvents = events
    }
    
    func getMoreUpvotedPosts() {
        Task {
            sectionLoading = "upvoted"
            let posts = try await postManager.getUpvotedPostFromCoreData()
            upvotedPosts = posts
            sectionLoading = ""
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
        let poVents = coreDataManager.getSavedPosts()
        let posts = poVents.filter { $0.isPost }
        let events = poVents.filter { !$0.isPost }
        savedPosts = try await postManager.getPostsFromIds(ids: posts.map({$0.id ?? ""})).filter({$0.id != ""})
        savedEvents = try await eventManager.getEventsFromIds(ids: events.map({$0.id ?? ""})).filter({$0.id != ""})
    }
}
