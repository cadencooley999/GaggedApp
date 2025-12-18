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
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
    }
}

class UserManager {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress = ""
    
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
    
    func setNewProfileImage(address: String) async throws {
        try await usersCollection.document(userId).updateData(["imageAddress": address])
    }
    
    func createUser(user: AuthDataResultModel, usernm: String, imageAddress: String) async throws {
        let userData: [String:Any] = [
            "uid" : user.uid,
            "email" : user.email,
            "imageAddress" : imageAddress,
            "garma" : 0,
            "username" : usernm,
            "createdAt": Timestamp(date: Date())
        ]
        try await usersCollection.document(user.uid).setData(userData, merge: false)
        userEmail = user.email
        userId = user.uid
        username = usernm
        chosenProfileImageAddress = imageAddress
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
    
    func reauthenticateAndChangePassword(
        email: String,
        currentPassword: String,
        newPassword: String
    ) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        // Silent re-auth
        try await user.reauthenticate(with: credential)

        // Retry password change
        try await user.updatePassword(to: newPassword)
    }
    
    func changeUsername(newUsername: String) async throws {
        try await usersCollection.document(userId).updateData([
            "username": newUsername,
            "lastUsernameChange": Timestamp(date: Date())
        ])
    }

    func lastChange() async throws -> Date? {
        let userData = try await usersCollection.document(userId).getDocument()
        
        guard let last = userData["lastUsernameChange"] as? Timestamp else {
            // Never changed before → allowed
            return nil
        }
        
        return last.dateValue()
    }
    
    
    func forgotPassword(email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmed)
            print("✅ Reset email sent")
        } catch {
            print("❌ Firebase error:", error.localizedDescription)
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
    
    func fetchUser(userId: String) async throws -> UserModel {
        let doc = try await usersCollection.document(userId).getDocument()
        let user = mapDoc(doc)
        return user
    }
    
    func fetchUsers(userIds: [String]) async throws -> [UserModel] {
        guard !userIds.isEmpty else { return [] }

        var users: [UserModel] = []

        // 10 IDs per Firestore "in" query
        let chunks = userIds.chunked(into: 10)

        for chunk in chunks {
            let snapshot = try await usersCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            for doc in snapshot.documents {
                if let user = try? mapDoc(doc) {
                    users.append(user)
                }
            }
        }

        return users
    }

    
    func updateProfileImage(imageUrl: String, userId: String) async throws {
        try await usersCollection.document(userId).updateData(["imageAddress": imageUrl])
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
        let id = doc["uid"] as? String ?? ""
        let username = doc["username"] as? String ?? "Anonymous"
        let imageAddress = doc["imageAddress"] as? String ?? ""
        let garma = doc["garma"] as? Int ?? 0
        let createdAt = doc["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let keywords = doc["keywords"] as? [String] ?? []
        
        print("mapping doc", id)
        
        return UserModel(id: id, username: username, garma: garma, imageAddress: imageAddress, createdAt: createdAt, keywords: keywords)
    }
}

