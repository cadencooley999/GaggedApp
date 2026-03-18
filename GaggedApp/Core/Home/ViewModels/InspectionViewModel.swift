//
//  InspectionViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/27/26.
//
import Foundation
import SwiftUI

@MainActor
class InspectionViewModel: ObservableObject {
    let reportManager = ReportManager.shared
    
    // MARK: - Published State (lists for the view)
    @Published var reportedPosts: [ReportedPost] = []
    @Published var reportedPolls: [ReportedPoll] = []
    @Published var reportedComments: [ReportedComment] = []
    
    // Loading flags per content type
    @Published var postsIsLoading: Bool = false
    @Published var pollsIsLoading: Bool = false
    @Published var commentsIsLoading: Bool = false
    
    // Has-more flags per content type
    @Published var hasMorePosts: Bool = true
    @Published var hasMorePolls: Bool = true
    @Published var hasMoreComments: Bool = true
    
    // MARK: - Pagination cursors (reuse existing cursor types)
    private var postsCursor: ReportContentCursor? = nil
    private var pollsCursor: ReportContentCursor? = nil
    private var commentsCursor: ReportContentCursor? = nil
    
    // MARK: - Seen IDs (dedupe pattern)
    private var seenPostIds = Set<String>()
    private var seenPollIds = Set<String>()
    private var seenCommentIds = Set<String>()
    
    // MARK: - Reset
    func resetPosts() {
        reportedPosts.removeAll()
        postsCursor = nil
        hasMorePosts = true
        seenPostIds.removeAll()
    }
    
    func resetPolls() {
        reportedPolls.removeAll()
        pollsCursor = nil
        hasMorePolls = true
        seenPollIds.removeAll()
    }
    
    func resetComments() {
        reportedComments.removeAll()
        commentsCursor = nil
        hasMoreComments = true
        seenCommentIds.removeAll()
    }
    
    func resetAll() {
        resetPosts()
        resetPolls()
        resetComments()
    }
    
    // MARK: - Initial Loads
    func loadInitialReportedPosts() async {
        resetPosts()
        await fetchMoreReportedPosts()
    }
    
    func loadInitialReportedPolls() async {
        resetPolls()
        await fetchMoreReportedPolls()
    }
    
    func loadInitialReportedComments() async {
        resetComments()
        await fetchMoreReportedComments()
    }
    
    // MARK: - Fetch More (pagination)
    func fetchMoreReportedPosts() async {
        guard !postsIsLoading, hasMorePosts else { return }
        postsIsLoading = true
        defer { postsIsLoading = false }
        
        do {
            let response = try await reportManager.fetchReportedPosts(cursor: postsCursor)
            
            let newItems = response.0.filter { seenPostIds.insert($0.post.id).inserted }
            withAnimation(.easeInOut(duration: 0.3)) {
                reportedPosts.append(contentsOf: newItems)
            }
            postsCursor = response.1
            hasMorePosts = response.1 != nil
        } catch {
            print("Failed to fetch reported posts:", error)
        }
    }
    
    func fetchMoreReportedPolls() async {
        guard !pollsIsLoading, hasMorePolls else { return }
        pollsIsLoading = true
        defer { pollsIsLoading = false }
        
        do {
            // TODO: Replace with real call when implemented in ReportManager
            let response = try await reportManager.fetchReportedPolls(cursor: pollsCursor)
            
            let newItems = response.0.filter { seenPollIds.insert($0.pollwithoptions.id).inserted }
            withAnimation(.easeInOut(duration: 0.3)) {
                reportedPolls.append(contentsOf: newItems)
            }
            pollsCursor = response.1
            hasMorePolls = response.1 != nil
        } catch {
            print("Failed to fetch reported polls:", error)
        }
    }
    
    func fetchMoreReportedComments() async {
        guard !commentsIsLoading, hasMoreComments else { return }
        commentsIsLoading = true
        defer { commentsIsLoading = false }
        
        do {
            // TODO: Replace with real call when implemented in ReportManager
            let response = try await reportManager.fetchReportedComments(cursor: commentsCursor)
            
            let newItems = response.0.filter { seenCommentIds.insert($0.comment.id).inserted }
            withAnimation(.easeInOut(duration: 0.3)) {
                reportedComments.append(contentsOf: newItems)
            }
            commentsCursor = response.1
            hasMoreComments = response.1 != nil
        } catch {
            print("Failed to fetch reported comments:", error)
        }
    }
    
    func approvePost(postId: String) async throws {
        try await reportManager.approvePost(postId: postId)
        withAnimation(.easeInOut(duration: 0.3)) {
            reportedPosts.removeAll(where: {$0.post.id == postId})
        }
        
    }
    
    func approvePoll(pollId: String) async throws {
        try await reportManager.approvePoll(pollId: pollId)
        withAnimation(.easeInOut(duration: 0.3)) {
            reportedPolls.removeAll(where: {$0.pollwithoptions.id == pollId})
        }
    }
    
    func approveComment(commentId: String) async throws {
        try await reportManager.approveComment(commentId: commentId)
        withAnimation(.easeInOut(duration:0.3)) {
            reportedComments.removeAll(where: {$0.comment.id == commentId})
        }
    }
    
    func deletePost(postId: String, authorId: String) async throws {
        try await FirebasePostManager.shared.deletePost(postId: postId)
        try await reportManager.deleteReports(contentId: postId)
        try await UserManager.shared.addStrikeAndCheckBan(userId: authorId)
        withAnimation(.easeInOut(duration: 0.3)) {
            reportedPosts.removeAll(where: {$0.post.id == postId})
        }
    }
    
    func deletePoll(pollId: String, authorId: String) async throws {
        try await PollManager.shared.deletePoll(pollId: pollId)
        try await reportManager.deleteReports(contentId: pollId)
        try await UserManager.shared.addStrikeAndCheckBan(userId: authorId)
        withAnimation(.easeInOut(duration: 0.3)) {
            reportedPolls.removeAll(where: {$0.pollwithoptions.id == pollId})
        }
    }
    
    func deleteComment(commentId: String, authorId: String) async throws {
        try await CommentsManager.shared.deleteComment(commentId: commentId)
        try await reportManager.deleteReports(contentId: commentId)
        try await UserManager.shared.addStrikeAndCheckBan(userId: authorId)
        print("survived")
        withAnimation(.easeInOut(duration: 0.3)) {
            reportedComments.removeAll(where: {$0.comment.id == commentId})
        }
    }
    
    func refreshFeedPoll(pollId: String, optionToAdd: String, optionToSubtract: String) {
        if let index = reportedPolls.firstIndex(where: {$0.pollwithoptions.id == pollId}) {
            var poll = reportedPolls[index]
            if optionToAdd != "" {
                if let optionIdx = poll.pollwithoptions.options.firstIndex(where: {$0.id == optionToAdd}) {
                    print("added")
                    poll.pollwithoptions.options[optionIdx].voteCount += 1
                    poll.pollwithoptions.poll.totalVotes += 1
                }
            }
            if optionToSubtract != "" {
                if let optionIdx = poll.pollwithoptions.options.firstIndex(where: {$0.id == optionToSubtract}) {
                    print("subtracted")
                    poll.pollwithoptions.options[optionIdx].voteCount -= 1
                    poll.pollwithoptions.poll.totalVotes -= 1
                }
            }
            PollCache.shared.cacheOptions(pollId: poll.pollwithoptions.id, options: poll.pollwithoptions.options)
            if let idx = reportedPolls.firstIndex(where: {$0.pollwithoptions.id == pollId}) {
                print("found loadedPolls indx")
                reportedPolls[idx] = poll
            }
        }
    }
}
