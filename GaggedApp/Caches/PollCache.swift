//
//  PollCache.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/25/26.
//

import Foundation
import SwiftUI

class PollCache {
    static let shared = PollCache()
    
    private var pollCache: [String: PollModel] = [:]
    private var pollWithOptionsCache: [String: PollWithOptions] = [:]
    private var optionsCache: [String: [PollOption]] = [:]
    
    func cacheOptions(pollId: String, options: [PollOption]) {
        optionsCache[pollId] = options
    }
    
    func digPollOptions(pollId: String) -> [PollOption]? {
        return optionsCache[pollId]
    }
    
    func clearCache() {
        pollCache = [:]
    }
}
