//
//  OnboardingViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/26/25.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

@MainActor
final class OnboardingViewModel: ObservableObject {
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    let storageManager = StorageManager.shared
    
    func signInEmailAndPassword(email: String, password: String, username: String, imageAddress: String = "ProfPic1") async throws {
        do {
            let newUser = try await UserManager.shared.signUpUser(email: email, password: password)
            try await UserManager.shared.createUser(user: newUser, usernm: username, imageAddress: imageAddress)
            hasOnboarded = true
            isLoggedIn = true
        }
        catch  {
            print("error with user creation: \(error)")
            throw error
        }
    }
}
