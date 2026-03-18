//
//  UserListenerManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 3/7/26.
//


import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class UserListenerManager {
    
    @AppStorage("isBanned") var isBanned: Bool = false
    @AppStorage("expirationDate") var expirationDate = Date()

    static let shared = UserListenerManager()

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    @Published var currentUser: User?

    func startListening() {

        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }

        // Prevent duplicate listeners
        if listener != nil { return }

        listener = db.collection("Users")
            .document(uid)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("User listener error:", error)
                    return
                }

                guard let data = snapshot?.data() else {
                    print("User document missing")
                    return
                }

                do {
                    if let expiration = data["banExpires"] as? Timestamp {
                        if expiration.dateValue() > Date() {
                            self?.isBanned = true
                            self?.expirationDate = expiration.dateValue()
                        } else {
                            self?.isBanned = false
                        }
                    }
                    else {
                        self?.isBanned = false
                    }
                } catch {
                    print("Decoding error:", error)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
