//
//  PostViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/7/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

@MainActor
final class PostViewModel: ObservableObject {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    
    @Published var post: PostModel?
    @Published var postAuthor: UserModel?
    @Published var postCities: [City] = []
    @Published var isLoading: Bool = false
    @Published var commentsIsLoading: Bool = false
    @Published var comments: [viewCommentModel] = []
    @Published var upvotedComms: [String] = []
    @Published var userUpvoted: Bool = false
    @Published var userDownvoted: Bool = false
    
    let postManager = FirebasePostManager.shared
    let commentManager = CommentsManager.shared
    let coreDataManager = CoreDataManager.shared
    let cityManager = CityManager.shared
    let userManager = UserManager.shared
    let voteManager = VoteManager.shared
    
    func isSaved(postId: String) async -> Bool {
        let posts = coreDataManager.getSavedPosts()
        print("posts: \(posts)")
        if posts.contains(where: {$0.id == postId}) {
            return true
        }
        else {
            return false
        }
    }
    
    func userVoted(postId: String) {
        if let votedPost = coreDataManager.getVotedPost(withId: postId) {
            if votedPost.isUpvoted == true {
                userUpvoted = true
                userDownvoted = false
            }
            else {
                userDownvoted = true
                userUpvoted = false
            }
        }
        else {
            userUpvoted = false
            userDownvoted = false
        }
    }
    
    func fetchPost(postId: String) async throws -> PostModel {
        let post = try await postManager.getPost(id: postId)
        return post
    }
    
    func fetchPostAuthor(authorId: String) {
        Task {
            let user = try await userManager.fetchUser(userId: authorId)
            self.postAuthor = user
        }
    }
    
    func setPost(postSelection: PostModel) {
        post = postSelection
        userVoted(postId: postSelection.id)
        fetchPostAuthor(authorId: postSelection.authorId)
        getAllComUpvoted(postId: postSelection.id)
        postCities = cityManager.getCities(ids: postSelection.cityIds)
    }
    
    func savePost(postId: String) {
        coreDataManager.savePost(postId: postId)
        print("Saved")
    }
    
    func unSavePost(postId: String) {
        coreDataManager.deleteSaved(id: postId)
        print("unSaved")
    }
    
    func deletePost(postId: String) async throws {
        guard postId != "" else {
            return
        }
        try await postManager.deletePost(postId: postId)
        
    }
    
    func deleteComment(commentId: String) async throws {
        guard commentId != "" else {
            return
        }
        try await commentManager.deleteComment(commentId: commentId)
    }
    
    func upvote(post: PostModel) {
        Task {
            try await voteManager.uploadVote(vote: VoteModel(postId: post.id, userId: userId, timestamp: nil, upvote: true), cityIds: post.cityIds)
            try await postManager.upvotePost(postId: post.id)
            coreDataManager.saveVotedPost(id: post.id, isUpvoted: true)
            self.post?.upvotes += 1
            userUpvoted = true
        }
    }
    
    func removeUpvote(post: PostModel) {
        Task {
            try await voteManager.deleteVote(postId: post.id, userId: userId)
            try await postManager.removeUpvote(postId: post.id)
            coreDataManager.removeVote(id: post.id)
            self.post?.upvotes -= 1
            userUpvoted = false
        }
    }
    
    func downvote(post: PostModel) {
        Task {
            try await voteManager.uploadVote(vote: VoteModel(postId: post.id, userId: userId, timestamp: nil, upvote: false), cityIds: post.cityIds)
            try await postManager.downvotePost(postId: post.id)
            coreDataManager.saveVotedPost(id: post.id, isUpvoted: false)
            self.post?.downvotes += 1
            userDownvoted = true
        }
    }
    
    func removeDownvote(post: PostModel) {
        Task {
            try await voteManager.deleteVote(postId: post.id, userId: userId)
            try await postManager.removeDownvote(postId: post.id)
            coreDataManager.removeVote(id: post.id)
            self.post?.downvotes -= 1
            userDownvoted = false
        }
    }
    
    func upvoteCom(comId: String) {
        Task {
            try await commentManager.upvoteComment(commentId: comId)
            coreDataManager.addCommentVote(commentId: comId, postId: post?.id ?? "")
            upvotedComms.append(comId)
            comments[comments.firstIndex(where: {$0.id == comId}) ?? 0].uiComment.comment.upvotes += 1
        }
    }
    
    func removeComUpvote(comId: String) {
        Task {
            try await commentManager.removeCommentUpvote(id: comId)
            coreDataManager.removeCommentVote(commentId: comId)
            upvotedComms.removeAll(where: {$0 == comId})
            comments[comments.firstIndex(where: {$0.id == comId}) ?? 0].uiComment.comment.upvotes -= 1
        }
    }
    
    func getAllComUpvoted(postId: String) {
        upvotedComms = coreDataManager.getPostCommentVotes(postId: postId).map({$0.commentId ?? ""})
    }
    
    func fetchComments() async throws {
        if let post = post {
            print("Fetching Comments")
            let coms = try await commentManager.getComments(postId: post.id)
            print(coms)
            let viewComs = mapComments(comments: coms, layer: 0)
            comments = orderComments(comments: viewComs)
        }
    }
    
    func mapComments(comments: [UICommentModel], layer: Int) -> [viewCommentModel] {
        var finalComs: [viewCommentModel] = []
        for c in comments {
            finalComs.append(viewCommentModel(uiComment: c, isExpanded: false, id: c.comment.id, indentLayer: getIndentLayer(com: c.comment), numChildren: getNumChildren(com: c.comment, comments: comments), isGrandchild: layer > 0 ? true : false))
        }
        return finalComs
    }
    
    func getNumChildren(com: CommentModel, comments: [UICommentModel]) -> Int {
        guard com.hasChildren else {return 0}
        
        return comments.count(where: {$0.comment.parentCommentId == com.id})
    }
    
    func getNumChildren2(com: CommentModel, comments: [viewCommentModel]) -> Int {
        guard com.hasChildren else {return 0}
        
        return comments.count(where: {$0.uiComment.comment.parentCommentId == com.id})
    }
    
    @MainActor
    func fetchChildren(viewComment: viewCommentModel, limit: Int = 0) async throws -> [viewCommentModel] {
        guard limit < 10 else { return [] }
        guard let post = post else { return [] }

        // Fetch direct children
        let childComms = try await commentManager.getChildComments(postId: post.id, commentId: viewComment.id)
        var newChildComs = mapComments(comments: childComms, layer: limit)
        newChildComs = orderComments(comments: newChildComs)

        var allChildren: [viewCommentModel] = []

        for child in newChildComs {
            //Recursively fetch deeper children if needed
            if child.uiComment.comment.hasChildren {
                print("Fetching children in recursion")
                let grandchildren = try await fetchChildren(viewComment: child, limit: limit + 1)
                allChildren.append(child)
                allChildren.append(contentsOf: grandchildren)
            } else {
                allChildren.append(child)
            }
        }
        
        print("ALL CHILDREN: ", allChildren)

        return allChildren
    }
    
    @MainActor
    func catchChildren(viewCom: viewCommentModel) async throws {
        do {
            let theChildren = try await fetchChildren(viewComment: viewCom)
            assignChildren(firstCom: viewCom, commentList: theChildren)
            comments = comments
        } catch {
            print("Error fetching children: \(error)")
        }
    }
    
    @MainActor
    func assignChildren(firstCom: viewCommentModel, commentList: [viewCommentModel]) {
        guard let parentIndex = comments.firstIndex(where: { $0.id == firstCom.id }) else {
            comments.append(contentsOf: commentList)
            return
        }

        comments.insert(contentsOf: commentList, at: parentIndex + 1)
        comments[parentIndex].isExpanded = true
        comments[parentIndex].numChildren = commentList.count
    }

    
    func getAuthorName(id: String) -> String? {
        return comments.first(where: {$0.id == id})?.uiComment.author.username
    }
    
    func collapseComments(viewComment: viewCommentModel) {
        comments.removeAll(where: {$0.uiComment.comment.parentCommentId == viewComment.id})
        if let index = comments.firstIndex(where: {$0.id == viewComment.id}) {
            comments[index].isExpanded = false
        }
    }
    
    func uploadComment(message: String, parentId: String?) async throws {
        if let post = post {
            let newComment = CommentModel(id: UUID().uuidString, postId: post.id, postName: post.name, message: message, authorId: userId, createdAt: Timestamp(date: Date()), upvotes: 0, parentCommentId: parentId ?? "", hasChildren: false, isOnEvent: false)
            if parentId != nil {
                try await commentManager.updateToParent(commentId: parentId!)
            }
            try await commentManager.uploadComment(comment: newComment)
        }
    }
    
    func hasParent(id: String) -> Bool {
        if comments.first(where: {$0.id == id})?.uiComment.comment.parentCommentId != "" {
            return true
        }
        return false
    }
    
    func getIndentLayer(com: CommentModel) -> Int {
        print("Getting indent layer for \(com.id)")
        guard com.parentCommentId != "" else {
            print("Gaurded out")
            return 0
        }
        
        var layer = 1
        var id = com.parentCommentId
        while true {
            if let parent = comments.first(where: {$0.uiComment.comment.id == id}) {
                if parent.uiComment.comment.parentCommentId == nil {
                    return layer
                }
                else {
                    layer += 1
                    id = parent.uiComment.comment.parentCommentId!
                }
            }
            else {
                return layer
            }
        }
    }
    
    func timeAgoString(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let secondsAgo = Int(Date().timeIntervalSince(date))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let month = 30 * day
        let year = 12 * month
        
        if secondsAgo < 5 {
            return "just now"
        } else if secondsAgo < minute {
            return "\(secondsAgo)s"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h"
        } else if secondsAgo < month {
            return "\(secondsAgo / day)d"
        } else if secondsAgo < year {
            return "\(secondsAgo / month)mo"
        } else {
            return "\(secondsAgo / year)yr"
        }
    }
    
    func orderComments(comments: [viewCommentModel]) -> [viewCommentModel] {
        let now = Date()
        let nowSeconds = now.timeIntervalSince1970

        return comments.sorted { (a: viewCommentModel, b: viewCommentModel) -> Bool in
//            // Convert timestamps to seconds since 1970
//            let createdASeconds = a.uiComment.comment.createdAt.dateValue().timeIntervalSince1970
//            let createdBSeconds = b.uiComment.comment.createdAt.dateValue().timeIntervalSince1970
//
//            // Compute ages in hours
//            let ageA = (nowSeconds - createdASeconds) / 3600.0
//            let ageB = (nowSeconds - createdBSeconds) / 3600.0
//
//            // Each factor explicitly typed as Double
//            let upvoteA = Double(a.uiComment.comment.upvotes) * 1.0
//            let upvoteB = Double(b.uiComment.comment.upvotes) * 1.0
//
//            let childrenA = Double(a.numChildren) * 0.75
//            let childrenB = Double(b.numChildren) * 0.75
//
//            let recencyA = -ageA * 0.5
//            let recencyB = -ageB * 0.5
//
//            let weightA = upvoteA + childrenA + recencyA
//            let weightB = upvoteB + childrenB + recencyB
//
//            return weightA > weightB
            return a.uiComment.comment.createdAt.dateValue().timeIntervalSince1970 < b.uiComment.comment.createdAt.dateValue().timeIntervalSince1970
        }
    }
}

extension PostViewModel {
    static func previewModel() -> PostViewModel {
        let vm = PostViewModel()
        let fakepost = PostModel(id: "12341234", text: "Camping Night was super fun but he had no hair and his baldness was frightening and he didn't care and he kept talking about meese and Canada and maple syrup. He is a player I think",          name: "David G",      imageUrl: "Moose", createdAt: Timestamp(date: Date().addingTimeInterval(-29000)), authorId: "Caden", height: 120, cityIds: ["NYC001"], keywords: [], upvotes: 0, downvotes: 0)
        vm.post = fakepost
        return vm
    }
}
