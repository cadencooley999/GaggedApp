//
//  CommentsCache.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/28/25.
//

import Foundation

class CommentsCache {
    static let shared = CommentsCache()
    
    private var cache: [String: [CommentModel]] = [:]
    
    func cacheComment(com: CommentModel, postId: String) {
        if var ref = cache[postId] {
            ref.append(com)
            cache[postId] = ref
        }
        else {
           cache[postId] = [com]
        }
    }
    
    func cacheComments(coms: [CommentModel], postId: String) {
        print("caching")
        if var ref = cache[postId] {
            ref.append(contentsOf: coms)
            cache[postId] = ref
        }
        else {
            cache[postId] = coms
        }
    }
    
    func replaceCache(coms: [CommentModel], postId: String) {
        cache[postId] = coms
    }
    
    func digPostComments(postId: String) -> [CommentModel]? {
        return cache[postId] ?? nil
    }
    
    func deleteComment(commentId: String, postId: String) {
        var newCache: [CommentModel] = cache[postId] ?? []
        newCache.removeAll(where: {$0.id == commentId})
        cache[postId] = newCache
    }
    
    func clearPost(postId: String) {
        cache.removeValue(forKey: postId)
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func updateToParent(commentId: String, postId: String) {
        if let ref = cache[postId] {
            let index = ref.firstIndex(where: {$0.id == commentId})!
            cache[postId]?[index].hasChildren = true
        }
    }
}
