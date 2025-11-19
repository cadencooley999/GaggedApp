//
//  LoginViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/16/25.
//

import Foundation
import SwiftUI

final class LoginViewModel: ObservableObject {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    
    let userManager = UserManager.shared
    
    func login(email: String, password: String) async -> Bool {
        do {
            let userData = try await userManager.logInUser(email: email, password: password)
            // Update AppStorage
            userId = userData.uid
            userEmail = email
            return true
        } catch {
            print("Login failed:", error.localizedDescription)
            return false
        }
    }
}
