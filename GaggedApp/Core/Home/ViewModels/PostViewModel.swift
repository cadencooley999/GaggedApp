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
    @Published var rootComments: [viewCommentModel] = []
    @Published var upvotedComms: [String] = []
    @Published var userUpvoted: Bool = false
    @Published var userDownvoted: Bool = false
    @Published var hasMoreComments: Bool = true
    @Published var upvoteLoading: Bool = false
    
    private var rootCommentIDs = Set<String>()

    func appendRootComments(_ new: [viewCommentModel]) {
        let filtered = new.filter { rootCommentIDs.insert($0.id).inserted }
        withAnimation(.easeInOut(duration: 0.3)) {
            rootComments.append(contentsOf: filtered)
        }
    }
    
    func appendRootComment(_ new: viewCommentModel) {
        if !rootComments.contains(where: {$0.id == new.id}) {
            rootCommentIDs.insert(new.id)
            withAnimation(.easeInOut(duration: 0.3)) {
                rootComments.append(new)
            }
        }
    }
    
    let postManager = FirebasePostManager.shared
    let commentManager = CommentsManager.shared
    let cityManager = CityManager.shared
    let userManager = UserManager.shared
    let voteManager = VoteManager.shared
    let avatarCacheManager = UserAvatarCache.shared
    
    private var commentsCursor: CommentsCursor? = nil
    
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
    
    func deleteComment(commentId: String, postId: String, ancestorId: String) async throws {
        guard commentId != "" else {
            return
        }
        try await commentManager.deleteComment(commentId: commentId)
        if ancestorId.isEmpty {
            rootComments.removeAll(where: {$0.id == commentId})
        } else {
            if let idx = rootComments.firstIndex(where: {$0.id == ancestorId}) {
                rootComments[idx].commentThreadState?.children.removeAll(where: {$0.id == commentId})
            }
        }
        CommentsCache.shared.setCache(coms: rootComments, postId: postId)
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
            print("delete failed ")
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
    
    func upvoteCom(comId: String, ancestorId: String, isRoot: Bool) {
        guard !upvoteLoading else {return}
        if let post = post {
            upvoteLoading = true
            Task {
                upvotedComms.append(comId)
                try await commentManager.upvoteComment(commentId: comId)
                CoreDataManager.shared.addCommentVote(commentId: comId, postId: post.id)
    //            rootComments[comments.firstIndex(where: {$0.id == comId}) ?? 0].comment.upvotes += 1
                if isRoot {
                    if let idx = rootComments.firstIndex(where: {$0.id == comId}) {
                        rootComments[idx].comment.upvotes += 1
                        print("gotem")
                    }
                } else {
                    if let idx = rootComments.firstIndex(where: {$0.id == ancestorId}) {
                        if let secIdx = rootComments[idx].commentThreadState?.children.firstIndex(where: {$0.id == comId}) {
                            rootComments[idx].commentThreadState?.children[secIdx].comment.upvotes += 1
                        }
                    }
                }
                CommentsCache.shared.setCache(coms: rootComments, postId: post.id)
                upvoteLoading = false
            }
        }
    }
    
    func removeComUpvote(comId: String, ancestorId: String, isRoot: Bool) {
        guard !upvoteLoading else {return}
        if let post = post {
            upvoteLoading = true
            Task {
                upvotedComms.removeAll(where: {$0 == comId})
                try await commentManager.upvoteComment(commentId: comId)
                CoreDataManager.shared.addCommentVote(commentId: comId, postId: post.id)
                if isRoot {
                    if let idx = rootComments.firstIndex(where: {$0.id == comId}) {
                        if rootComments[idx].comment.upvotes > 0 {
                            rootComments[idx].comment.upvotes -= 1
                        }
                    }
                } else {
                    if let idx = rootComments.firstIndex(where: {$0.id == ancestorId}) {
                        if let secIdx = rootComments[idx].commentThreadState?.children.firstIndex(where: {$0.id == comId}) {
                            if rootComments[idx].commentThreadState?.children[secIdx].comment.upvotes ?? 0 > 0 {
                                rootComments[idx].commentThreadState?.children[secIdx].comment.upvotes -= 1
                            }
                        }
                    }
                }
                CommentsCache.shared.setCache(coms: rootComments, postId: post.id)
                upvoteLoading = false
            }
        }
    }
    
    func getAllComUpvoted(postId: String) {
        upvotedComms = CoreDataManager.shared.getPostCommentVotes(postId: postId).map({$0.commentId ?? ""})
    }
    
    func loadInitialRootComments(blockedIds: [String]) async throws {
        resetRootComments()
        let hadCache = fetchCachedRoots()
        if !hadCache {try await fetchRootComments(blockedIds: blockedIds)}
    }
        
    func resetRootComments() {
        commentsCursor = nil
        hasMoreComments = true
        rootCommentIDs = Set()
        rootComments.removeAll()
    }
    
    func fetchCachedRoots() -> Bool {
        if let post = post {
            var comments: [viewCommentModel] = []
            if let cached = CommentsCache.shared.digRootComments(postId: post.id) {
                print("getting from cache")
                comments.append(contentsOf: cached)
                hasMoreComments = CommentsCache.shared.digHasMore(postId: post.id)
                commentsCursor = CommentsCache.shared.digCursor(postId: post.id)
                appendRootComments(comments)
                return true
            }
        }
        return false
    }
    
    func fetchRootComments(limit: Int = 10, blockedIds: [String]) async throws {
        print("fetch root triggered")
        defer {commentsIsLoading = false}
        if let post = post {
            var comments: [viewCommentModel] = []
            print("hasMoreComments: ", hasMoreComments)
            if hasMoreComments {
                commentsIsLoading = true
                let response = try await commentManager.getRootComments(postId: post.id, limit: limit, blockedUserIds: blockedIds, cursor: commentsCursor)
                commentsCursor = response.1
                let mapped = mapComments(comments: response.0)
                comments.append(contentsOf: mapped)
                hasMoreComments = response.1 != nil
            }
            appendRootComments(comments)
            CommentsCache.shared.setCache(coms: rootComments, postId: post.id)
            CommentsCache.shared.setCacheHasMore(postId: post.id, hasMore: hasMoreComments)
            CommentsCache.shared.setCacheCursor(postId: post.id, cursor: commentsCursor)
            updateAvatarCache(for: comments)
        }
    }
    
    func fetchChildren(limit: Int = 10, rootComment: viewCommentModel) async throws {
        // if has more, show button
        // if has loaded replies just expand = true
        // if has loaded and expand == true, if has more then fetch more and then store and cache
        // expanded means has replies loaded and is showing them all
        if let post = post {
            if let idx = rootComments.firstIndex(where: {$0.id == rootComment.id}) {
                var newRoot = rootComment
                if rootComment.commentThreadState?.isExpanded == false {
                    newRoot.commentThreadState?.isExpanded = true
                }
                if rootComment.commentThreadState?.hasMore == true || (rootComment.comment.hasChildren && rootComment.commentThreadState?.children.isEmpty == true){
                    let response = try await commentManager.fetchChildren(ancestorId: rootComment.id, limit: limit, cursor: rootComment.commentThreadState?.cursor)
                    newRoot.commentThreadState?.cursor = response.1
                    if let threadState = newRoot.commentThreadState {
                        let seenChildrenIds = Set(threadState.children.map(\.id))
                        let newComs = mapComments(comments: response.0).filter({!seenChildrenIds.contains($0.id)})
                        newRoot.commentThreadState?.children.append(contentsOf: newComs)
                        newRoot.commentThreadState?.hasMore = response.1 != nil
                        updateAvatarCache(for: newComs)
                    }
                }
                rootComments[idx] = newRoot
            }
            CommentsCache.shared.setCache(coms: rootComments, postId: post.id)
            CommentsCache.shared.setCacheHasMore(postId: post.id, hasMore: hasMoreComments)
        }
    }
        
//    func fetchComments() async throws {
//        if let post = post {
//            var viewComs: [viewCommentModel] = []
//            var newComments: [CommentModel] = []
//            var shouldCache = false
//            if let cached = CommentsCache.shared.digPostComments(postId: post.id) {
//                print("retrieving cached comments...")
//                newComments = cached
//                let withExComments: [CommentWithExpanded] = newComments.map { cm in
//                    let hasChildren = newComments.contains(where: { $0.parentCommentId == cm.id })
//                    return CommentWithExpanded(comment: cm, isExpanded: hasChildren)
//                }
//                viewComs = mapCachedComments(comments: withExComments)
//                print(newComments.count)
//            } else {
//                print("network fetching comments...")
//                newComments = try await commentManager.getComments(postId: post.id)
//                viewComs = mapComments(comments: newComments)
//                shouldCache = true
//            }
//            print("view coms", viewComs)
//            let ordered = orderHierarchically(viewComs)
//            print("ordered count", ordered.count)
//            comments = ordered
//            updateAvatarCache(for: ordered)
//            if shouldCache {
//                print("caching comments...")
//                CommentsCache.shared.replaceCache(coms: newComments, postId: post.id)
//            }
//        }
//    }
    
//    func refreshComments() async throws {
//        if let post = post {
//            var newComments: [CommentModel] = []
//            CommentsCache.shared.clearPost(postId: post.id)
//            newComments = try await commentManager.getComments(postId: post.id)
//            let viewComs = mapComments(comments: newComments)
//            let coms = orderHierarchically(viewComs)
//            comments = coms
//            updateAvatarCache(for: coms)
//            CommentsCache.shared.replaceCache(coms: newComments, postId: post.id)
//        }
//    }
    
    func updateAvatarCache(for coms: [viewCommentModel]) {
        let userIds = Set(coms.map { $0.comment.authorId })
        let uncachedUserIds = userIds.filter({avatarCacheManager.getAvatar(for: $0) == nil})
        
        Task {
            var newAvatars: [String:String] = try await UserManager.shared.fetchAvatars(uniqueIds: uncachedUserIds)
            for (userId, avatar) in newAvatars {
                UserAvatarCache.shared.setAvatar(avatar, for: userId)
                for idx in rootComments.indices {
                    if rootComments[idx].comment.authorId == userId {
                        rootComments[idx].comment.authorProfPic = avatar
                    }
                }
            }
            if let post = post {
                CommentsCache.shared.setCache(coms: rootComments, postId: post.id)
                print("cache restored")
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
            finalComs.append(viewCommentModel(comment: c, id: c.id, commentThreadState: CommentThreadState(children: [], cursor: nil, hasMore: false, isLoading: false, isExpanded: true)))
        }
        return finalComs
    }
    
    func mapComment(comment: CommentModel) -> viewCommentModel {
        var newCom = comment
        if let cachedAddress = avatarCacheManager.getAvatar(for: comment.authorId) {
            newCom.authorProfPic = cachedAddress
        }
        return viewCommentModel(comment: newCom, id: newCom.id, commentThreadState: CommentThreadState(children: [], cursor: nil, hasMore: false, isLoading: false, isExpanded: true))
    }
    
    func uploadComment(message: String, parentId: String?, parentAuthorId: String?, parentAuthorName: String?, ancestorId: String?) async throws {
        if let post = post {
            print("uploading from view model")
            do {
                let newId = UUID().uuidString
                let newComment = CommentModel(id: newId, postId: post.id, postName: post.name, message: message, authorId: userId, authorName: username, authorProfPic: chosenProfileImageAddress, createdAt: Timestamp(date: Date()), upvotes: 0, parentCommentId: parentId ?? "", parentAuthorId: parentAuthorId ?? "", parentAuthorName: parentAuthorName ?? "", ancestorId: ancestorId ?? "", hasChildren: false, isOnEvent: false, isGrand: isGrand(parentId: parentId ?? "", ancestorId: ancestorId ?? ""))
                try await commentManager.uploadComment(comment: newComment)
                CommentsCache.shared.cacheComment(com: mapComment(comment: newComment), postId: post.id)
                userManager.addGags(userId: userId, contributionType: .comment)
                if ancestorId != nil {
                    print("is reply")
                    try await commentManager.updateToParent(commentId: ancestorId ?? "")
                    if let idx = rootComments.firstIndex(where: {$0.id == ancestorId}) {
                        var ancestor = rootComments[idx]
                        print("appending to ancestor")
                        if ancestor.commentThreadState?.children.count == 0 {
                            if ancestor.comment.hasChildren == true {
                                ancestor.commentThreadState?.hasMore = true
                            }
                        }
                        ancestor.commentThreadState?.children.append(mapComment(comment: newComment))
                        ancestor.comment.hasChildren = true
                        rootComments[idx] = ancestor
                    }
                }
                else {
                    appendRootComment(mapComment(comment: newComment))
                }
                CommentsCache.shared.setCache(coms: rootComments, postId: post.id)
                CommentsCache.shared.setCacheHasMore(postId: post.id, hasMore: hasMoreComments)
            } catch {
                print(error)
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
            return a.comment.createdAt.dateValue().timeIntervalSince1970 < b.comment.createdAt.dateValue().timeIntervalSince1970
        }
    }
    
    func isGrand(parentId: String, ancestorId: String) -> Bool {
         
        guard !(ancestorId.isEmpty) else {return false}

        if !(parentId.isEmpty) {
            if let index = rootComments.firstIndex(where: {$0.id == ancestorId}) {
                if rootComments[index]
                    .commentThreadState?
                    .children
                    .contains(where: { $0.id == parentId }) == true {
                    return true
                }
            }
        }

        return false
    }
    
    func getCommentFromId(id: String) -> viewCommentModel? {
        return rootComments.first(where: {$0.id == id}) ?? nil
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

