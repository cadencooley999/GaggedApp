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
    let coreDataManager = CoreDataManager.shared
    
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
        if !hasLoaded {
            isLoading = true
            feedStore.loadedPolls = try await pollManager.fetchPolls(cityIds: cityIds)
            hasLoaded = true
            isLoading = false
        }
    }
    
    func getMorePolls(cityIds: [String]) async throws {
        polls = []  
        isLoading = true
        feedStore.loadedPolls = try await pollManager.fetchPolls(cityIds: cityIds)
        isLoading = false
    }
    
    func sendVote(pollId: String, optionId: String) async throws {
        coreDataManager.addPollVote(pollId: pollId, optionId: optionId)
        try await pollManager.addPollVote(pollId: pollId, optionId: optionId)
    }
    
    func removeVote(pollId: String, optionId: String) async throws {
        coreDataManager.removePollVote(pollId: pollId)
        try await pollManager.removePollVote(pollId: pollId, optionId: optionId)
    }
    
    func switchVote(pollId: String, oldOptionId: String, newOptionId: String) async throws {
        coreDataManager.removePollVote(pollId: pollId)
        coreDataManager.addPollVote(pollId: pollId, optionId: newOptionId)
        try await pollManager.switchVote(pollId: pollId, oldOptionId: oldOptionId, newOptionId: newOptionId)
    }
    
    func getPollChoice(pollId: String) -> String {
        return coreDataManager.getPollChoice(pollId: pollId)
    }
    
}
