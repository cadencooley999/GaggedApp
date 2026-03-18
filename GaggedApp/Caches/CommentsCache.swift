//
//  CommentsCache.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/28/25.
//

import Foundation

class CommentsCache {
    static let shared = CommentsCache()
    
    private var cache: [String: [viewCommentModel]] = [:]
    private var hasMoreCache: [String: Bool] = [:]
    private var cursorCache: [String: CommentsCursor?] = [:]
    
    func cacheComment(com: viewCommentModel, postId: String) {
        if var ref = cache[postId] {
            ref.append(com)
            cache[postId] = ref
        }
        else {
           cache[postId] = [com]
        }
    }
    
    func cacheComments(coms: [viewCommentModel], postId: String) {
        print("caching")
        if var ref = cache[postId] {
            ref.append(contentsOf: coms)
            print("coms", coms)
            cache[postId] = ref
        }
        else {
            print("coms", coms)
            cache[postId] = coms
        }
    }
    
    func setCache(coms: [viewCommentModel], postId: String) {
        cache[postId] = coms
    }
    
    func setCacheHasMore(postId: String, hasMore: Bool) {
        hasMoreCache[postId] = hasMore
    }
    
    func digHasMore(postId: String) -> Bool {
        if let bool = hasMoreCache[postId] {
            return bool
        }
        return false
    }
    
    func setCacheCursor(postId: String, cursor: CommentsCursor?) {
        cursorCache[postId] = cursor
    }
    
    func digCursor(postId: String) -> CommentsCursor? {
        if let cur = cursorCache[postId] {
            return cur
        }
        return nil
    }
    
    func cacheChildren(coms: [viewCommentModel], parentId: String, postId: String) {
        var ref: [viewCommentModel] = []
        if var oldRef = cache[postId] {
            if let index = cache[postId]?.firstIndex(where: {$0.id == parentId}) {
                if let threadState = oldRef[index].commentThreadState {
                    let existingIds = Set(threadState.children.map(\.id))
                    let newComs = coms.filter({!existingIds.contains($0.id)})
                    ref = newComs
                    oldRef[index].commentThreadState?.children.append(contentsOf: ref)
                    cache[postId] = oldRef
                }
            }
        }
        
    }
    
    func replaceCache(coms: [viewCommentModel], postId: String) {
        cache[postId] = coms
    }
    
    func digRootComments(postId: String) -> [viewCommentModel]? {
        return cache[postId] ?? nil
    }
    
    func deleteComment(commentId: String, postId: String) {
        var newCache: [viewCommentModel] = cache[postId] ?? []
        newCache.removeAll(where: {$0.id == commentId})
        cache[postId] = newCache
    }
    
    func clearPost(postId: String) {
        cache.removeValue(forKey: postId)
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func updateRootToParent(commentId: String, postId: String) {
        if let ref = cache[postId] {
            if let index = ref.firstIndex(where: {$0.id == commentId}) {
                cache[postId]?[index].comment.hasChildren = true
            }
        }
    }
}
