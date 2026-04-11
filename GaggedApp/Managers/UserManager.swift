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

enum ContributionType {
    case post
    case comment
    case poll
}

struct AuthDataResultModel {
    let uid: String
    let email: String
    let isAdmin: Bool
    
    init(user: User, isAdmin: Bool) {
        self.uid = user.uid
        self.email = user.email ?? ""
        self.isAdmin = isAdmin
    }
}

enum UserManagerError: Error { case missingUserId, documentNotFound }

class UserManager {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress = ""
    @AppStorage("isAdmin") var isAdmin = false
    @AppStorage("isBanned") var isBanned = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    let specificDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1, hour: 0, minute: 0))! // Example for a specific date
    
    let oldDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 0, minute: 0))!
    
    let usersCollection = Firestore.firestore().collection("Users")
    
    static let shared = UserManager()
    
    private init() {}
    
    @discardableResult
    func signUpUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let claims = try await authDataResult.user.getIDTokenResult(forcingRefresh: true)
        let isAdmin = claims.claims["isAdmin"] as? Bool ?? false
        return AuthDataResultModel(user: authDataResult.user, isAdmin: isAdmin)
    }
    
    func setNewProfileImage(address: String) async throws {
        guard !userId.isEmpty else { throw UserManagerError.missingUserId }
        let ref = usersCollection.document(userId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw UserManagerError.documentNotFound }
        try await ref.updateData(["imageAddress": address])
    }
    
    func createUser(user: AuthDataResultModel, usernm: String, imageAddress: String) async throws {
        let userData: [String:Any] = [
            "uid" : user.uid,
            "email" : user.email,
            "imageAddress" : imageAddress,
            "gags" : 0,
            "username" : usernm,
            "createdAt": Timestamp(date: Date()),
            "numPosts" : 0,
            "notificationsEnabled" : false,
            "strikes" : 0,
        ]
        try await usersCollection.document(user.uid).setData(userData, merge: false)
        userEmail = user.email
        userId = user.uid
        username = usernm
        chosenProfileImageAddress = imageAddress
        isAdmin = user.isAdmin
    }
    
    func addStrikeAndCheckBan(userId: String) async throws {
        let userRef = usersCollection.document(userId)

        do {
            try await Firestore.firestore().runTransaction { transaction, errorPointer in
                
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(userRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                print("snapshot exists:", snapshot.exists)
                print("here1")
                let data = snapshot.data() ?? [:]
                let strikes = data["strikes"] as? Int ?? 0
                let newStrikes = strikes + 1
                
                var updates: [String: Any] = [
                    "strikes": newStrikes
                ]
                print("here2")

                if newStrikes >= 3 {
                    let twoWeeksFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date())!
                    updates["banExpires"] = Timestamp(date: twoWeeksFromNow)
                }
                print("here3")
                transaction.updateData(updates, forDocument: userRef)
                print("here4")
                return nil
            }
        }
        catch {
            print(error)
        }
    }
    
    func logInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authresult = try await Auth.auth().signIn(withEmail: email, password: password)
        let claims = try await authresult.user.getIDTokenResult(forcingRefresh: true)
        let isAdmin = claims.claims["isAdmin"] as? Bool ?? false
        return AuthDataResultModel(user: authresult.user, isAdmin: isAdmin)
    }
    
    func signOutUser() async throws {
        do {
            try Auth.auth().signOut()
            await MainActor.run {
                // Clear local persisted state to avoid stale UI
                self.userEmail = ""
                self.userId = ""
                self.username = ""
                self.chosenProfileImageAddress = ""
                self.isAdmin = false
                self.isBanned = false
                self.isLoggedIn = false
            }
            print("User signed out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            throw signOutError
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
        guard !userId.isEmpty else { throw UserManagerError.missingUserId }
        let ref = usersCollection.document(userId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw UserManagerError.documentNotFound }
        try await ref.updateData([
            "username": newUsername,
            "lastUsernameChange": Timestamp(date: Date())
        ])
        
    }
    
    func fetchUserImageAddress(userId: String) async throws -> String {
        guard userId != "" else {return ""}
        do {
            let doc = try await usersCollection.document(userId).getDocument()
            guard doc.exists else { return "" }
            return doc["imageAddress"] as? String ?? ""
        }
        catch {
            print(error)
            return ""
        }
    }
    
    func fetchAvatars(uniqueIds: Set<String>) async throws -> [String: String] {
        guard !uniqueIds.isEmpty else { return [:] }

        var avatarDict: [String: String] = [:]

        // Firestore 'in' queries allow up to 10 values
        let chunks = uniqueIds.chunked(into: 10)

        for chunk in chunks {
            let snapshot = try await usersCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            for document in snapshot.documents {
                let id = document.documentID
                let address = document["imageAddress"] as? String ?? ""
                avatarDict[id] = address
            }
        }

        return avatarDict
    }

    func lastChange() async throws -> Date? {
        guard !userId.isEmpty else { return nil }
        let doc = try await usersCollection.document(userId).getDocument()
        guard doc.exists else { return nil }
        guard let last = doc["lastUsernameChange"] as? Timestamp else {
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

        // 1. Reauthenticate
        try await user.reauthenticate(with: credential)

        // 2. Attempt Firestore cleanup FIRST
        do {
            try await cleanupUserData(userId: user.uid)
        } catch {
            print("Firestore cleanup failed:", error.localizedDescription)
            throw error  // 🚫 STOP here — user is still signed in
        }
        
        self.userEmail = ""
        self.userId = ""
        self.username = ""
        self.chosenProfileImageAddress = ""
        self.isLoggedIn = false
        // 3. Only delete auth user if cleanup succeeded
        try await user.delete()
    }
    
    func cleanupUserData(userId: String) async throws {
        guard !userId.isEmpty else { return }
        try await usersCollection.document(userId).delete()
    }
    
    func fetchUser(userId: String) async throws -> UserModel {
        guard !userId.isEmpty else { throw UserManagerError.missingUserId }
        let doc = try await usersCollection.document(userId).getDocument()
        guard doc.exists else { throw UserManagerError.documentNotFound }
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
                if doc.exists, let user = try? mapDoc(doc) {
                    users.append(user)
                }
            }
        }

        return users
    }

    
    func updateProfileImage(imageUrl: String, userId: String) async throws {
        guard !userId.isEmpty else { throw UserManagerError.missingUserId }
        let ref = usersCollection.document(userId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw UserManagerError.documentNotFound }
        try await ref.updateData(["imageAddress": imageUrl])
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
        let gags = doc["gags"] as? Int ?? 0
        let createdAt = doc["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let keywords = doc["keywords"] as? [String] ?? []
        let numPosts = doc["numPosts"] as? Int ?? 0
        
        print("mapping doc", id)
        
        return UserModel(id: id, username: username, gags: gags, imageAddress: imageAddress, createdAt: createdAt, numPosts: numPosts, keywords: keywords)
    }
    
    func addGags(userId: String, contributionType: ContributionType) {
        Task {
            guard !userId.isEmpty else { return }
            switch contributionType {
            case .post:
                try await usersCollection.document(userId).updateData(["gags": FieldValue.increment(Int64(10))])
            case .comment:
                try await usersCollection.document(userId).updateData(["gags": FieldValue.increment(Int64(4))])
            case .poll:
                try await usersCollection.document(userId).updateData(["gags": FieldValue.increment(Int64(8))])
            }
        }
    }
}

