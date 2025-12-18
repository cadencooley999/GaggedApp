//
//  MixedType.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/1/25.
//
import Foundation

enum MixedType: Identifiable, Hashable {
    case post(PostModel)
    case event(EventModel)
    
    var id: String {
        switch self {
        case .post(let post): return "post-\(post.id)"
        case .event(let event): return "event-\(event.id)"
        }
    }
}
