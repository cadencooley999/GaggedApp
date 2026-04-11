//
//  PollsViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/18/25.
//

import SwiftUI
import Foundation
import Combine

@MainActor
class PollsViewModel: ObservableObject {
    
    private let feedStore: FeedStore
    var cancellables: Set<AnyCancellable> = []
    private var ingestedPollIDs = Set<String>()

    @Published var polls: [PollWithOptions] = []
    @Published var hasLoaded: Bool = false
    @Published var isLoading: Bool = false
    @Published var poll: PollWithOptions? = nil
    @Published var hasMore: Bool = true
    @Published var blocked: [String] = []
    @Published var blockedBy: [String] = []
    
    @Published var columns: [GridItem] = [GridItem()]
    
    let pollManager = PollManager.shared
    
    private var cursor: PollFeedCursor? = nil
    
    
    init(feedStore: FeedStore) {
        self.feedStore = feedStore
        bindFeedStore()
    }
    
    private func bindFeedStore() {
        feedStore.$loadedPolls
            .sink { [weak self] polls in
                guard let self else{ return }
                
                print("poll sink triggered")
                
                let newPolls = polls.filter {
                    self.ingestedPollIDs.insert($0.id).inserted
                }

                guard !newPolls.isEmpty else { return }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.polls.append(contentsOf: newPolls)
                }
            }
            .store(in: &cancellables)
        
        feedStore.$blocked.sink { [weak self] ids in
            self?.blocked = Array(ids)
        }.store(in: &cancellables)
        
        feedStore.$blockedBy.sink { [weak self] ids in
            self?.blockedBy = Array(ids)
        }.store(in: &cancellables)
    }
    
    func fetchPoll(id: String) async throws -> PollWithOptions {
        let poll = try await pollManager.fetchPollById(id: id)
        return poll
    }
    
    func removePollFromFeed(id: String) {
        feedStore.loadedPolls.removeAll(where: {$0.id == id})
    }
    
    func getInitialPolls(cityIds: [String]) async throws {
        reset()
        try await getMorePolls(cityIds: cityIds)
    }
    
    func reset() {
        feedStore.loadedPolls.removeAll()
        hasLoaded = false
        polls.removeAll()
        hasMore = true
        cursor = nil
        ingestedPollIDs.removeAll()
    }
    
    func getMorePolls(cityIds: [String]) async throws {
        guard !isLoading, hasMore else { return }
        isLoading = true
        hasLoaded = false
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            let response = try await pollManager.fetchPolls(cityIds: cityIds, blockedUserIds: Array(Set(self.blocked + self.blockedBy)), cursor: cursor)
            feedStore.loadedPolls.append(contentsOf: response.polls)
            cursor = response.nextCursor
            hasMore = response.nextCursor != nil
        }
        catch {
            throw NetworkErrors.ErrorFetching
        }
    }
    
    func sendVote(pollId: String, optionId: String) async throws {
        CoreDataManager.shared.addPollVote(pollId: pollId, optionId: optionId)
        do {
            try await pollManager.addPollVote(pollId: pollId, optionId: optionId)
        } catch {
            CoreDataManager.shared.removePollVote(pollId: pollId)
            throw NetworkErrors.ErrorUploading
        }
    }
    
    func removeVote(pollId: String, optionId: String) async throws {
        CoreDataManager.shared.removePollVote(pollId: pollId)
        do {
            try await pollManager.removePollVote(pollId: pollId, optionId: optionId)
        }
        catch {
            CoreDataManager.shared.addPollVote(pollId: pollId, optionId: optionId)
            throw NetworkErrors.ErrorUploading
        }
    }
    
    func switchVote(pollId: String, oldOptionId: String, newOptionId: String) async throws {
        CoreDataManager.shared.removePollVote(pollId: pollId)
        CoreDataManager.shared.addPollVote(pollId: pollId, optionId: newOptionId)
        do {
            try await pollManager.switchVote(pollId: pollId, oldOptionId: oldOptionId, newOptionId: newOptionId)
        }
        catch {
            CoreDataManager.shared.removePollVote(pollId: pollId)
            CoreDataManager.shared.addPollVote(pollId: pollId, optionId: oldOptionId)
        }
    }
    
    func refreshFeedPoll(pollId: String, optionToAdd: String, optionToSubtract: String) {
        if let index = feedStore.loadedPolls.firstIndex(where: {$0.id == pollId}) {
            var poll = feedStore.loadedPolls[index]
            if optionToAdd != "" {
                if let optionIdx = poll.options.firstIndex(where: {$0.id == optionToAdd}) {
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
            PollCache.shared.cacheOptions(pollId: pollId, options: poll.options)
            feedStore.loadedPolls[index] = poll
        }
        polls = feedStore.loadedPolls
    }
    
    func getPollChoice(pollId: String) -> String {
        return CoreDataManager.shared.getPollChoice(pollId: pollId)
    }
    
    func isSaved(pollId: String) async -> Bool {
        let posts = CoreDataManager.shared.getSavedPolls()
        if posts.contains(where: {$0.id == pollId}) {
            return true
        }
        else {
            return false
        }
    }
    
    func deletePoll(pollId: String) async throws {
        guard pollId != "" else {return}
        try await pollManager.deletePoll(pollId: pollId)
        feedStore.loadedPolls.removeAll(where: {$0.id == pollId})
        polls.removeAll(where: {$0.id == pollId})
    }
}

