//
//  UserAvatarCache.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/27/25.
//


final class UserAvatarCache {
    static let shared = UserAvatarCache()
    private init() {}

    private var cache: [String: String] = [:] // userId → avatarId

    func getAvatar(for userId: String) -> String? {
        return cache[userId] ?? ""
    }

    func setAvatar(_ avatarId: String, for userId: String) {
        cache[userId] = avatarId
    }

    func invalidate(userId: String) {
        cache[userId] = nil
    }
}
