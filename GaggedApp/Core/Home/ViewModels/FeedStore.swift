//
//  FeedStore.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/24/25.
//
import SwiftUI

@MainActor
final class FeedStore: ObservableObject {
    @Published var allPostsTriggered: Bool = false
    @Published var allPollsTriggered: Bool = false
    @Published var loadedPosts: [PostModel] = []
    @Published var loadedPolls: [PollWithOptions] = []
    @Published var selectedCityIDs: [String] = []
}
