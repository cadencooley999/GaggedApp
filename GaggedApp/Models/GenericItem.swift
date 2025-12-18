//
//  GenericItem.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/9/25.
//

enum GenericItem: Identifiable {
    case post(PostModel)
    case comment(CommentModel)
    
    var id: String {
        switch self {
        case .post(let post): return "\(post.id)"
        case .comment(let comment): return "\(comment.id)"
        }
    }
    
    var authorId: String {
        switch self {
        case .post(let post): return "\(post.authorId)"
        case .comment(let comment): return "\(comment.authorId)"
        }
    }
    
}
