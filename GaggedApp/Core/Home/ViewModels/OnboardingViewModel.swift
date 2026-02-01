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
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress = ""
    
    let storageManager = StorageManager.shared
    
    func signInEmailAndPassword(email: String, password: String, username: String, imageAddress: String = "ProfPic1") async throws {
        let newUser = try await UserManager.shared.signUpUser(email: email, password: password)
        try await UserManager.shared.createUser(user: newUser, usernm: username, imageAddress: imageAddress)
        userEmail = newUser.email
        userId = newUser.uid
        self.username = username
        chosenProfileImageAddress = imageAddress
        CoreDataManager.setup(userId: newUser.uid)
        hasOnboarded = true
        isLoggedIn = true
    }
}
