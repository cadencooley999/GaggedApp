//
//  SettingsViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/16/25.
//
import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true

    @Published var nameMentionNotifications: Bool = false
    @Published var nameToWatchFor: String = ""
    
    let userManager = UserManager.shared
    
    func logOut(userId: String) {
        Task {
            try await userManager.signOutUser()
            CoreDataManager.teardown()
            isLoggedIn = false
        }
    }
    
    func deleteAccount(password: String) async throws -> Bool {
        do {
            try await userManager.reauthAndDelete(email: userEmail, password: password)
            CoreDataManager.teardown()
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
