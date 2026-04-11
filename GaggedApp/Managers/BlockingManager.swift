//
//  BlockingManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 3/29/26.
//

import Foundation
import FirebaseFirestore

class BlockingManager {
    
    static let shared = BlockingManager()
    
    let usersCollection: CollectionReference = Firestore.firestore().collection("Users")
    
    func fetchBlocked(userId: String) async throws -> Set<String> {
        let blocked = try await usersCollection.document(userId).collection("Blocked").getDocuments()
        
        let ids = Set(Array(blocked.documents.map({$0.documentID})))
        
        return ids
    }
    
    func fetchBlockedBy(userId: String) async throws -> Set<String> {
        let blockedBy = try await usersCollection.document(userId).collection("BlockedBy").getDocuments()
        
        let ids = Set(Array(blockedBy.documents.map({$0.documentID})))
        
        return ids
    }
    
    func blockUser(userId: String, targetId: String) async throws {
        guard userId != targetId else { return }
        let batch = Firestore.firestore().batch()
        let blockedRef = usersCollection.document(userId).collection("Blocked").document(targetId)
        let blockedByRef = usersCollection.document(targetId).collection("BlockedBy").document(userId)
        batch.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: blockedRef)
        batch.setData(["createdAt":FieldValue.serverTimestamp()], forDocument: blockedByRef)
        try await batch.commit()
    }

    func unblockUser(userId: String, targetId: String) async throws {
        let batch = Firestore.firestore().batch()
        let blockedRef = usersCollection.document(userId).collection("Blocked").document(targetId)
        let blockedByRef = usersCollection.document(targetId).collection("BlockedBy").document(userId)
        batch.deleteDocument(blockedRef)
        batch.deleteDocument(blockedByRef)
        try await batch.commit()
    }
    
}
