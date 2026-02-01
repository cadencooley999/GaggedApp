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
    
    @Published var polls: [PollWithOptions] = []
    @Published var hasLoaded: Bool = false
    @Published var isLoading: Bool = false
    
    let pollManager = PollManager.shared
    
    init(feedStore: FeedStore) {
        self.feedStore = feedStore
        bindFeedStore()
    }
    
    private func bindFeedStore() {
        feedStore.$loadedPolls
            .sink { [weak self] polls in
                self?.polls = polls
            }
            .store(in: &cancellables)
    }
    
    func getPollsIfNeeded(cityIds: [String]) async throws {
        guard hasLoaded == false else { return }
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            feedStore.loadedPolls = try await pollManager.fetchPolls(cityIds: cityIds)
            hasLoaded = true
        }
        catch {
            throw NetworkErrors.ErrorFetching
        }
    }
    
    func getMorePolls(cityIds: [String]) async throws {
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            let newPolls = try await pollManager.fetchPolls(cityIds: cityIds)
            polls = []
            feedStore.loadedPolls = newPolls
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
    }
}

