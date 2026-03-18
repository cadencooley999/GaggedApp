//
//  LoginViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/16/25.
//

import Foundation
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress = ""
    @AppStorage("isAdmin") var isAdmin: Bool = false
    
    let userManager = UserManager.shared
    
    func login(email: String, password: String) async -> Bool {
        do {
            let userData = try await userManager.logInUser(email: email, password: password)
            let user = try await userManager.fetchUser(userId: userData.uid)
            userEmail = userData.email
            userId = user.id
            username = user.username
            chosenProfileImageAddress = user.imageAddress
            isAdmin = user.isAdmin
            CoreDataManager.setup(userId: userId)
            return true
        } catch {
            print("Login failed:", error.localizedDescription)
            return false
        }
    }
}
