//
//  UserManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/26/25.
//
import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AuthDataResultModel {
    let uid: String
    let email: String
    let photoURL: String
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
        self.photoURL = user.photoURL?.absoluteString ?? ""
    }
}

class UserManager {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("profImageUrl") var profImageUrl = ""
    
    let specificDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1, hour: 0, minute: 0))! // Example for a specific date
    
    let oldDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 0, minute: 0))!
    
    let usersCollection = Firestore.firestore().collection("Users")
    
    static let shared = UserManager()
    
    private init() {}
    
    @discardableResult
    func signUpUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func createUser(user: AuthDataResultModel, usernm: String, imageUrl: String) async throws {
        let userData: [String:Any] = [
            "uid" : user.uid,
            "email" : user.email,
            "imageURL" : imageUrl,
            "garma" : 0,
            "username" : usernm,
            "createdAt": Timestamp(date: Date())
        ]
        try await usersCollection.document(user.uid).setData(userData, merge: false)
        userEmail = user.email
        userId = user.uid
        username = usernm
        profImageUrl = imageUrl
    }
    
    func logInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authresult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResultModel(user: authresult.user)
    }
    
    func signOutUser() async throws {
        do {
            try Auth.auth().signOut()
            print("User signed out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func reauthAndDelete(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        // Reauthenticate
        _ = try await user.reauthenticate(with: credential)

        // Delete user
        try await user.delete()

        // Optional: clean up Firestore
        try await cleanupUserData(userId: user.uid)
    }
    
    func cleanupUserData(userId: String) async throws {
        try await usersCollection.document(userId).delete()
    }
    
    func loadUserInfo(userId: String) async throws -> UserModel {
        var doc = try await usersCollection.document(userId).getDocument()
        let user = mapDoc(doc)
        return user
    }
    
    func updateProfileImage(imageUrl: String, userId: String) async throws {
        try await usersCollection.document(userId).updateData(["imageURL": imageUrl])
    }
    
    func generateKeywords(username: String) -> [String] {
        let inputs = [username]
        
        var keywords: [String] = []
        
        for input in inputs {
            // Split each word in case the title or name has spaces (e.g., "Swift UI")
            let parts = input.lowercased().split(separator: " ")
            
            for part in parts {
                var prefix = ""
                for char in part {
                    prefix.append(char)
                    keywords.append(prefix)
                }
            }
        }
        
        return keywords
    }
    
    func mapDoc(_ doc: DocumentSnapshot) -> UserModel {
        let id = doc["userId"] as? String ?? ""
        let username = doc["username"] as? String ?? "Anonymous"
        let imageUrl = doc["imageUrl"] as? String ?? ""
        let garma = doc["garma"] as? Int ?? 0
        let createdAt = doc["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let keywords = doc["keywords"] as? [String] ?? []
        
        print("mapping doc", id)
        
        return UserModel(id: id, username: username, garma: garma, imageUrl: imageUrl, createdAt: createdAt, keywords: keywords)
    }
}
