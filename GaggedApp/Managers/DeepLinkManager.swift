//
//  DeepLinkManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/1/26.
//
import Foundation
import SwiftUI

final class DeepLinkManager {
    static let shared = DeepLinkManager()

    func handle(_ url: URL, navigateToPost: (String) -> Void, navigateToPoll: (String) -> Void) {
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 2 else { return }

        switch pathComponents[1] {
        case "post":
            let postId = pathComponents[2]
            navigateToPost(postId)

        case "poll":
            let pollId = pathComponents[2]
            navigateToPoll(pollId)

        default:
            break
        }
    }

}
