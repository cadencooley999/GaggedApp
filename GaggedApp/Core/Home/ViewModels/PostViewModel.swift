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
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress = ""
    
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
    let cityManager = CityManager.shared
    let userManager = UserManager.shared
    let voteManager = VoteManager.shared
    let avatarCacheManager = UserAvatarCache.shared
    
    func isSaved(postId: String) async -> Bool {
        let posts = CoreDataManager.shared.getSavedPosts()
        if posts.contains(where: {$0.id == postId}) {
            return true
        }
        else {
            return false
        }
    }
    
    func userVoted(postId: String) {
        if let votedPost = CoreDataManager.shared.getVotedPost(withId: postId) {
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
    
    func fetchPostAuthor(authorId: String) async throws -> UserModel {
        let author = try await userManager.fetchUser(userId: authorId)
        self.postAuthor = author
        return author
    }
    
    func setPost(postSelection: PostModel) {
        var newPost = postSelection
        if let cachedAddress = avatarCacheManager.getAvatar(for: postSelection.authorId) {
            newPost.authorPicUrl = cachedAddress
        }
        post = newPost
        userVoted(postId: newPost.id)
        getAllComUpvoted(postId: newPost.id)
        postCities = cityManager.getCities(ids: newPost.cityIds)
        updateAvatarCache(for: newPost)
    }
    
    func savePost(postId: String) {
        CoreDataManager.shared.savePost(postId: postId)
        print("Saved")
    }
    
    func unSavePost(postId: String) {
        CoreDataManager.shared.deleteSaved(id: postId)
        print("unSaved")
    }
    
    func deletePost(postId: String) async throws {
        guard postId != "" else {
            return
        }
        try await postManager.deletePost(postId: postId)
        
    }
    
    func deleteComment(commentId: String, postId: String) async throws {
        guard commentId != "" else {
            return
        }
        try await commentManager.deleteComment(commentId: commentId)
        CommentsCache.shared.deleteComment(commentId: commentId, postId: postId)
    }
    
    func upvote(post: PostModel) async throws {
        do {
            try await voteManager.uploadVote(vote: VoteModel(postId: post.id, userId: userId, timestamp: nil, upvote: true), cityIds: post.cityIds)
            try await postManager.upvotePost(postId: post.id)
            CoreDataManager.shared.saveVotedPost(id: post.id, isUpvoted: true)
            self.post?.upvotes += 1
            userUpvoted = true
        } catch {
            throw VoteError.uploadFailed
        }
    }
    
    func removeUpvote(post: PostModel) async throws {
        do {
            try await voteManager.deleteVote(postId: post.id, userId: userId)
            try await postManager.removeUpvote(postId: post.id)
            CoreDataManager.shared.removeVote(id: post.id)
            self.post?.upvotes -= 1
            userUpvoted = false
        } catch {
            throw VoteError.deleteFailed
        }
    }
    
    func downvote(post: PostModel) async throws {
        do {
            try await voteManager.uploadVote(vote: VoteModel(postId: post.id, userId: userId, timestamp: nil, upvote: false), cityIds: post.cityIds)
            try await postManager.downvotePost(postId: post.id)
            CoreDataManager.shared.saveVotedPost(id: post.id, isUpvoted: false)
            self.post?.downvotes += 1
            userDownvoted = true
        } catch {
            throw VoteError.uploadFailed
        }
    }
    
    func removeDownvote(post: PostModel) async throws {
        do {
            try await voteManager.deleteVote(postId: post.id, userId: userId)
            try await postManager.removeDownvote(postId: post.id)
            CoreDataManager.shared.removeVote(id: post.id)
            self.post?.downvotes -= 1
            userDownvoted = false
        } catch {
            throw VoteError.deleteFailed
        }
    }
    
    func upvoteCom(comId: String) {
        Task {
            try await commentManager.upvoteComment(commentId: comId)
            CoreDataManager.shared.addCommentVote(commentId: comId, postId: post?.id ?? "")
            upvotedComms.append(comId)
            comments[comments.firstIndex(where: {$0.id == comId}) ?? 0].comment.upvotes += 1
        }
    }
    
    func removeComUpvote(comId: String) {
        Task {
            try await commentManager.removeCommentUpvote(id: comId)
            CoreDataManager.shared.removeCommentVote(commentId: comId)
            upvotedComms.removeAll(where: {$0 == comId})
            comments[comments.firstIndex(where: {$0.id == comId}) ?? 0].comment.upvotes -= 1
        }
    }
    
    func getAllComUpvoted(postId: String) {
        upvotedComms = CoreDataManager.shared.getPostCommentVotes(postId: postId).map({$0.commentId ?? ""})
    }
    
    func fetchComments() async throws {
        if let post = post {
            var viewComs: [viewCommentModel] = []
            var newComments: [CommentModel] = []
            var shouldCache = false
            if let cached = CommentsCache.shared.digPostComments(postId: post.id) {
                print("retrieving cached comments...")
                newComments = cached
                let withExComments: [CommentWithExpanded] = newComments.map { cm in
                    let hasChildren = newComments.contains(where: { $0.parentCommentId == cm.id })
                    return CommentWithExpanded(comment: cm, isExpanded: hasChildren)
                }
                viewComs = mapCachedComments(comments: withExComments)
                print(newComments.count)
            } else {
                print("network fetching comments...")
                newComments = try await commentManager.getComments(postId: post.id)
                viewComs = mapComments(comments: newComments)
                shouldCache = true
            }
            print("view coms", viewComs)
            let ordered = orderHierarchically(viewComs)
            print("ordered count", ordered.count)
            comments = ordered
            updateAvatarCache(for: ordered)
            if shouldCache {
                print("caching comments...")
                CommentsCache.shared.replaceCache(coms: newComments, postId: post.id)
            }
        }
    }
    
    func refreshComments() async throws {
        if let post = post {
            var newComments: [CommentModel] = []
            CommentsCache.shared.clearPost(postId: post.id)
            newComments = try await commentManager.getComments(postId: post.id)
            let viewComs = mapComments(comments: newComments)
            let coms = orderHierarchically(viewComs)
            comments = coms
            updateAvatarCache(for: coms)
            CommentsCache.shared.replaceCache(coms: newComments, postId: post.id)
        }
    }
    
    func updateAvatarCache(for coms: [viewCommentModel]) {
        let userIds = Set(coms.map { $0.comment.authorId })

        for userId in userIds {
            // Skip if already cached
            guard avatarCacheManager.getAvatar(for: userId) == nil else { continue }

            Task.detached(priority: .background) { [weak self] in
                guard let self = self else {return}
                if let latestAvatar = try? await UserManager.shared.fetchUserImageAddress(userId: userId) {
                    
                    UserAvatarCache.shared.setAvatar(latestAvatar, for: userId)
                    
                    await MainActor.run {
                        for i in self.comments.indices {
                            if self.comments[i].comment.authorId == userId {
                                self.comments[i].comment.authorProfPic = latestAvatar
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateAvatarCache(for post: PostModel) {
        guard avatarCacheManager.getAvatar(for: post.authorId) == nil else { return }
        
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else {return}
            if let latestAvatar = try? await UserManager.shared.fetchUserImageAddress(userId: post.authorId) {
                UserAvatarCache.shared.setAvatar(latestAvatar, for: post.authorId)
                await MainActor.run {
                    self.post?.authorPicUrl = latestAvatar
                }
            }
        }
    }
    
    func mapComments(comments: [CommentModel]) -> [viewCommentModel] {
        var finalComs: [viewCommentModel] = []
        for var c in comments {
            if let cachedAddress = avatarCacheManager.getAvatar(for: c.authorId) {
                c.authorProfPic = cachedAddress
            }
            finalComs.append(viewCommentModel(comment: c, isExpanded: false, id: c.id, isGrandchild: false, threadId: ""))
        }
        return finalComs
    }
    
    func mapCachedComments(comments: [CommentWithExpanded]) -> [viewCommentModel] {
        var finalComs: [viewCommentModel] = []
        for var c in comments {
            if let cachedAddress = avatarCacheManager.getAvatar(for: c.comment.authorId) {
                c.comment.authorProfPic = cachedAddress
            }
            finalComs.append(viewCommentModel(comment: c.comment, isExpanded: c.isExpanded, id: c.comment.id, isGrandchild: false, threadId: ""))
        }
        return finalComs
    }
    
    @MainActor
    func fetchChildren(viewComment: viewCommentModel, limit: Int = 0) async throws -> [viewCommentModel] {
        guard limit < 10 else { return [] }
        guard let post = post else { return [] }

        // Fetch direct children
        let childComms = try await commentManager.getChildComments(postId: post.id, commentId: viewComment.id)
        var newChildComs = mapComments(comments: childComms)
        print("found ", newChildComs.count, " children")
        for index in newChildComs.indices {
            if limit > 0 {
                newChildComs[index].isGrandchild = true
            }
        }
        newChildComs = orderComments(comments: newChildComs)

        var allChildren: [viewCommentModel] = []

        for child in newChildComs {
            //Recursively fetch deeper children if needed
            if child.comment.hasChildren {
                let grandchildren = try await fetchChildren(viewComment: child, limit: limit + 1)
                allChildren.append(child)
                allChildren.append(contentsOf: grandchildren)
            } else {
                allChildren.append(child)
            }
        }

        return allChildren
    }
    
    @MainActor
    func catchChildren(viewCom: viewCommentModel) async throws {
        do {
            let theChildren = try await fetchChildren(viewComment: viewCom)
            assignChildren(firstCom: viewCom, commentList: theChildren)
            print(theChildren)
            CommentsCache.shared.cacheComments(coms: theChildren.map({$0.comment}), postId: viewCom.comment.postId)
            print("Cache count: ", CommentsCache.shared.digPostComments(postId: viewCom.comment.postId)?.count ?? [])
            updateAvatarCache(for: comments)
            print("cached children")
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
    }

    
    func getAuthorName(id: String) -> String? {
        return comments.first(where: {$0.id == id})?.comment.authorName
    }
    
    func collapseComments(viewComment: viewCommentModel) {
        comments.removeAll(where: {$0.comment.parentCommentId == viewComment.id})
        if let index = comments.firstIndex(where: {$0.id == viewComment.id}) {
            comments[index].isExpanded = false
        }
    }
    
    func uploadComment(message: String, parentId: String?) async throws {
        if let post = post {
            do {
                let newComment = CommentModel(id: UUID().uuidString, postId: post.id, postName: post.name, message: message, authorId: userId, authorName: username, authorProfPic: chosenProfileImageAddress, createdAt: Timestamp(date: Date()), upvotes: 0, parentCommentId: parentId ?? "", hasChildren: false, isOnEvent: false)
                if parentId != nil {
                    try await commentManager.updateToParent(commentId: parentId!)
                }
                try await commentManager.uploadComment(comment: newComment)
                CommentsCache.shared.cacheComment(com: newComment, postId: post.id)
                if parentId != nil {
                    CommentsCache.shared.updateToParent(commentId: parentId ?? "", postId: post.id)
                }
                userManager.addGags(userId: userId, contributionType: .comment)
            } catch {
                print(error)
            }
        }
    }
    
    func hasParent(id: String) -> Bool {
        if comments.first(where: {$0.id == id})?.comment.parentCommentId != "" {
            return true
        }
        return false
    }
    
//    func getIndentLayer(com: CommentModel) -> Int {
//        guard com.parentCommentId != "" else {
//            return 0
//        }
//        
//        var layer = 1
//        var id = com.parentCommentId
//        while true {
//            if let parent = comments.first(where: {$0.comment.id == id}) {
//                if parent.comment.parentCommentId == nil {
//                    return layer
//                }
//                else {
//                    layer += 1
//                    id = parent.comment.parentCommentId!
//                }
//            }
//            else {
//                return layer
//            }
//        }
//    }
    
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
            return a.comment.createdAt.dateValue().timeIntervalSince1970 < b.comment.createdAt.dateValue().timeIntervalSince1970
        }
    }
    
    func orderHierarchically(_ models: [viewCommentModel]) -> [viewCommentModel] {

        var byId: [String: viewCommentModel] = [:]
        var children: [String: [viewCommentModel]] = [:]
        var roots: [viewCommentModel] = []

        // Build ID map WITHOUT nuking hasChildren
        for model in models {
            byId[model.comment.id] = model
        }

        // Assign children & roots
        for model in models {
            let parentId = model.comment.parentCommentId

            if parentId.isEmpty || byId[parentId] == nil {
                // Parent not loaded → treat as root
                roots.append(model)
            } else {
                children[parentId, default: []].append(model)
            }
        }

        // Mark parents as having children (only ever set true)
        for parentId in children.keys {
            if var parent = byId[parentId] {
                parent.comment.hasChildren = true
                byId[parentId] = parent
            }
        }

        // Sort chronologically
        roots.sort { $0.comment.createdAt.dateValue() < $1.comment.createdAt.dateValue() }
        for key in children.keys {
            children[key]?.sort {
                $0.comment.createdAt.dateValue() < $1.comment.createdAt.dateValue()
            }
        }

        var ordered: [viewCommentModel] = []

        func dfs(_ node: viewCommentModel, depth: Int) {
            var current = node
            current.isGrandchild = depth >= 2
            current.threadId = findGrandparent(comment: current)
            ordered.append(current)

            for child in children[node.comment.id] ?? [] {
                dfs(child, depth: depth + 1)
            }
        }

        for root in roots {
            dfs(root, depth: 0)
        }

        return ordered
    }
    
    func findGrandparent(comment: viewCommentModel) -> String {
        var current = comment

        while !current.comment.parentCommentId.isEmpty,
              let parent = getCommentFromId(id: current.comment.parentCommentId) {
            current = parent
        }

        return current.id
    }
    
    func getCommentFromId(id: String) -> viewCommentModel? {
        return comments.first(where: {$0.id == id}) ?? nil
    }

}

extension PostViewModel {
    static func previewModel() -> PostViewModel {
        let vm = PostViewModel()
        let fakepost = PostModel(id: "12341234", text: "Camping Night was super fun but he had no hair and his baldness was frightening and he didn't care and he kept talking about meese and Canada and maple syrup. He is a player I think",          name: "David G",      imageUrl: "Moose", createdAt: Timestamp(date: Date().addingTimeInterval(-29000)), authorId: "Caden", authorName: "CAden1", authorPicUrl: "ProfPic1", height: 120, cityIds: ["NYC001"], tags: [], keywords: [], upvotes: 0, downvotes: 0)
        vm.post = fakepost
        return vm
    }
}

