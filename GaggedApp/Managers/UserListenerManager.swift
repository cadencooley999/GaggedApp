//
//  UserListenerManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 3/7/26.
//


import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class UserListenerManager: ObservableObject {

    // MARK: - AppStorage (cache only)
    @AppStorage("isBanned") var isBanned: Bool = false
    @AppStorage("expirationDate") var expirationDate = Date()
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("chosenProfileImageAddress") var chosenProfileImageAddress = ""
    @AppStorage("isAdmin") var isAdmin = false
    @AppStorage("isLoggedIn") var isLoggedIn = false

    static let shared = UserListenerManager()

    private var listener: ListenerRegistration?
    private var authListener: AuthStateDidChangeListenerHandle?

    private let db = Firestore.firestore()

    @Published var currentUser: User?

    // MARK: - Init
    private init() {
        startAuthListener()
    }

    // MARK: - Auth Listener (SOURCE OF TRUTH)
    private func startAuthListener() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task {
                if let user = user {
                    print("✅ Firebase user active:", user.uid)

                    // Sync AppStorage
                    self.userId = user.uid
                    self.userEmail = user.email ?? ""
                    
                    let claims = try await user.getIDTokenResult(forcingRefresh: true)
                    self.isAdmin = claims.claims["isAdmin"] as? Bool ?? false

                    // Start Firestore listener
                    self.startUserListener(uid: user.uid)

                } else {
                    print("❌ Firebase user signed out")

                    try await self.signOutUser()
                }
            }
        }
    }

    // MARK: - Firestore User Listener
    private func startUserListener(uid: String) {

        // Prevent duplicate listeners
        if listener != nil { return }

        listener = db.collection("Users")
            .document(uid)
            .addSnapshotListener { [weak self] snapshot, error in

                guard let self else { return }

                if let error = error {
                    print("User listener error:", error)
                    return
                }

                guard let data = snapshot?.data() else {
                    print("User document missing")
                    return
                }

                // Ban logic
                if let expiration = data["banExpires"] as? Timestamp {
                    let date = expiration.dateValue()

                    if date > Date() {
                        self.isBanned = true
                        self.expirationDate = date
                    } else {
                        self.isBanned = false
                    }
                } else {
                    self.isBanned = false
                }

                // Optional: update other fields live
                self.username = data["username"] as? String ?? self.username
                self.chosenProfileImageAddress = data["imageAddress"] as? String ?? self.chosenProfileImageAddress
            }
    }

    // MARK: - Stop Listener
    func stopUserListener() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Sign Out
    func signOutUser() async throws {
        do {
            try Auth.auth().signOut()

            stopUserListener()

            await MainActor.run {
                self.userEmail = ""
                self.userId = ""
                self.username = ""
                self.chosenProfileImageAddress = ""
                self.isAdmin = false
                self.isBanned = false
                self.isLoggedIn = false
            }

            print("✅ User signed out cleanly")

        } catch {
            print("❌ Sign out error:", error)
            throw error
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async -> Bool {
        do {
            let userData = try await UserManager.shared.logInUser(email: email, password: password)
            let user = try await UserManager.shared.fetchUser(userId: userData.uid)

            await MainActor.run {
                self.userEmail = userData.email
                self.userId = user.id
                self.username = user.username
                self.chosenProfileImageAddress = user.imageAddress
                self.isAdmin = userData.isAdmin
                self.isLoggedIn = true
            }

            CoreDataManager.setup(userId: user.id)

            return true

        } catch {
            print("Login failed:", error.localizedDescription)
            return false
        }
    }
}
