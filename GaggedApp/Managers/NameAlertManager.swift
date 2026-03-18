//
//  AlertManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/7/26.
//

import Foundation
import FirebaseFirestore

enum NameAlertError: Error {
    case documentNotFound
    case invalidData
}

class NameAlertManager {
    static let shared = NameAlertManager()
    
    let alertsRef = Firestore.firestore().collection("NameAlerts")
    
    func addAlert(alert: NameAlertModel) async throws {
        print("Adding Alert")
        try await alertsRef.document(alert.userId).setData([
            "name": alert.name,
            "isActive": alert.isActive,
            "normalizedName" : alert.normalizedName,
            "city" : [alert.cityId],
            "userId" : alert.userId
        ])
    }
    
    func setAlertActive(userId: String, isActive: Bool) async throws{
        try await alertsRef.document(userId).updateData(["isActive" : isActive])
    }
    
    func changeAlertCity(newCity: String, userId: String) async throws {
        try await alertsRef.document(userId).updateData(["city" : newCity])
    }
    
    func changeAlertName(newName: String, userId: String) async throws {
        try await alertsRef.document(userId).updateData(["name" : newName, "normalizedName" : newName.normalizedForIndexing()])
    }
    
    func deleteAlert(userId: String) async throws {
        try await alertsRef.document(userId).delete()
    }
    
    func getAlert(userId: String) async throws -> NameAlertModel {
        let alertDoc = try await alertsRef.document(userId).getDocument()
        return try mapAlert(alertDoc: alertDoc)
    }
    
    func mapAlert(alertDoc: DocumentSnapshot) throws -> NameAlertModel {
        guard let data = alertDoc.data() else {
            throw NameAlertError.documentNotFound
        }
        let name = data["name"] as? String ?? ""
        let normalizedName = data["normalizedName"] as? String ?? name.lowercased()
        let isActive = data["isActive"] as? Bool ?? false
        // Prefer the stored userId field; if missing, fall back to the document ID
        let userId = data["userId"] as? String ?? alertDoc.documentID
        let cityId = data["city"] as? String ?? ""
        print("Mapping alert", data["city"])
        return NameAlertModel(name: name, normalizedName: normalizedName, isActive: isActive, userId: userId, cityId: cityId.isEmpty ? "" : cityId)
    }
}
