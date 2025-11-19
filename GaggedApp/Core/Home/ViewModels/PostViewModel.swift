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
    @Published var isLoading: Bool = false
    @Published var commentsIsLoading: Bool = false
    @Published var comments: [viewCommentModel] = []
    
    let postManager = FirebasePostManager.shared
    let commentManager = CommentsManager.shared
    let coreDataManager = CoreDataManager.shared
    
    func isSaved(postId: String) async -> Bool {
        let posts = await coreDataManager.getSavedPosts()
        print("posts: \(posts)")
        if posts.contains(where: {$0.id == postId}) {
            return true
        }
        else {
            return false
        }
    }
    
    func fetchPost(postId: String) async throws -> PostModel {
        let post = try await postManager.getPost(id: postId)
        return post
    }
    
    func setPost(postSelection: PostModel) {
        post = postSelection
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
            self.post?.upvotes += 1
            try await postManager.upvotePost(post: post)
        }
    }
    
    func downvote(post: PostModel) {
        Task {
            self.post?.downvotes += 1
            try await postManager.downvotePost(postId: post.id)
        }
    }
    
    func upvoteCom(comId: String) {
        Task {
            comments[comments.firstIndex(where: {$0.id == comId}) ?? 0].comment.upvotes += 1
            try await commentManager.upvoteComment(commentId: comId)
        }
    }
    
    func fetchComments() async throws {
        if let post = post {
            print("Fetching Comments")
            let coms = try await commentManager.getComments(postId: post.id)
            let viewComs = mapComments(comments: coms, layer: 0)
            comments = orderComments(comments: viewComs)
        }
    }
    
    func mapComments(comments: [CommentModel], layer: Int) -> [viewCommentModel] {
        var finalComs: [viewCommentModel] = []
        for c in comments {
            finalComs.append(viewCommentModel(comment: c, isExpanded: false, id: c.id, indentLayer: getIndentLayer(com: c), numChildren: getNumChildren(com: c, comments: comments), isGrandchild: layer > 0 ? true : false))
        }
        return finalComs
    }
    
    func getNumChildren(com: CommentModel, comments: [CommentModel]) -> Int {
        guard com.hasChildren else {return 0}
        
        return comments.count(where: {$0.parentCommentId == com.id})
    }
    
    func getNumChildren2(com: CommentModel, comments: [viewCommentModel]) -> Int {
        guard com.hasChildren else {return 0}
        
        return comments.count(where: {$0.comment.parentCommentId == com.id})
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
            if child.comment.hasChildren {
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

    
    func getAuthor(id: String) -> String? {
        return comments.first(where: {$0.id == id})?.comment.authorId
    }
    
    func collapseComments(viewComment: viewCommentModel) {
        comments.removeAll(where: {$0.comment.parentCommentId == viewComment.id})
        if let index = comments.firstIndex(where: {$0.id == viewComment.id}) {
            comments[index].isExpanded = false
        }
    }
    
    func uploadComment(message: String, parentId: String?) async throws {
        if let post = post {
            let newComment = CommentModel(id: UUID().uuidString, postId: post.id, postName: post.name,authorName: username, message: message, authorId: userId, createdAt: Timestamp(date: Date()), upvotes: 0, parentCommentId: parentId ?? "", hasChildren: false, isOnEvent: false)
            if parentId != nil {
                try await commentManager.updateToParent(commentId: parentId!)
            }
            try await commentManager.uploadComment(comment: newComment)
        }
    }
    
    func hasParent(id: String) -> Bool {
        if comments.first(where: {$0.id == id})?.comment.parentCommentId != "" {
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
            if let parent = comments.first(where: {$0.comment.id == id}) {
                if parent.comment.parentCommentId == nil {
                    return layer
                }
                else {
                    layer += 1
                    id = parent.comment.parentCommentId!
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
            // Convert timestamps to seconds since 1970
            let createdASeconds = a.comment.createdAt.dateValue().timeIntervalSince1970
            let createdBSeconds = b.comment.createdAt.dateValue().timeIntervalSince1970

            // Compute ages in hours
            let ageA = (nowSeconds - createdASeconds) / 3600.0
            let ageB = (nowSeconds - createdBSeconds) / 3600.0

            // Each factor explicitly typed as Double
            let upvoteA = Double(a.comment.upvotes) * 1.0
            let upvoteB = Double(b.comment.upvotes) * 1.0

            let childrenA = Double(a.numChildren) * 0.75
            let childrenB = Double(b.numChildren) * 0.75

            let recencyA = -ageA * 0.5
            let recencyB = -ageB * 0.5

            let weightA = upvoteA + childrenA + recencyA
            let weightB = upvoteB + childrenB + recencyB

            return weightA > weightB
        }
    }
}

extension PostViewModel {
    static func previewModel() -> PostViewModel {
        let vm = PostViewModel()
        let fakepost = PostModel(id: "12341234", text: "Camping Night was super fun but he had no hair and his baldness was frightening and he didn't care and he kept talking about meese and Canada and maple syrup. He is a player I think",          name: "David G",      imageUrl: "Moose", upvotes: 20, downvotes: 0,  createdAt: Timestamp(date: Date().addingTimeInterval(-29000)), authorId: "Caden", authorName: "Caden1123", height: 120, cityIds: ["NYC001"], keywords: [], upvotesThisWeek: 0, lastUpvoted: nil)
        vm.post = fakepost
        return vm
    }
}
