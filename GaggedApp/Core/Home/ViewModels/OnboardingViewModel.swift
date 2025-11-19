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
    
    @Published var pickedImage: UIImage? = nil
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            setImage(selection: imageSelection)
        }
    }
    
    @State var isLoading: Bool = false
    
    let storageManager = StorageManager.shared
    
    let patterns = ProfanityFilter.compileRegexPatterns(words: ProfanityFilter.bannedWords)
    
    func checkUsername(username: String) -> Bool {
        let isClean = ProfanityFilter.isUsernameClean(username, compiledPatterns: patterns)
        return isClean
    }
    
    private func setImage(selection: PhotosPickerItem?) {
        guard let selection else { return }
        
        Task {
            if let data = try await selection.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    pickedImage = uiImage
                    return
                }
            }
        }
    }
    
    func signInEmailAndPassword(email: String, password: String, username: String, image: UIImage?) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            var imageUrl = ""
            if let selectedImage = image {
                let imageId = UUID().uuidString
                imageUrl = try await storageManager.uploadImage(selectedImage, imageId: imageId)
            }
            let newUser = try await UserManager.shared.signUpUser(email: email, password: password)
            try await UserManager.shared.createUser(user: newUser, usernm: username, imageUrl: imageUrl)
            hasOnboarded = true
            isLoggedIn = true
        }
        catch  {
            print("error with user creation: \(error)")
            throw error
        }
    }
}
