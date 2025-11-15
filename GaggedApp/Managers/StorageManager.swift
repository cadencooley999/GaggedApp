//
//  StorageManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//
import Foundation
import FirebaseStorage
import UIKit
import FirebaseCore
import FirebaseFirestore

class StorageManager {
    static let shared = StorageManager()
    private var storage: Storage {
        Storage.storage()
    }
    func uploadImage(_ image: UIImage, imageId: String) async throws -> String {
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        let ref = storage.reference().child("images/\(imageId).jpg")
        
        // Upload data
        _ = try await ref.putDataAsync(imageData, metadata: nil)
        
        // Get download URL
        let url = try await ref.downloadURL()
        return url.absoluteString

    }
    
    func deleteImage(imageUrl: String) async throws {
        
        guard let imageId = imageUrl.extractImageId() else {
            throw NSError(domain: "StorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL — could not extract image ID"])
        }
        
        let ref = storage.reference().child("images/\(imageId)")
        try await ref.delete()
        print("Image \(imageId) deleted successfully")
    }
}

extension String {
    /// Extracts the Firebase image ID from a download URL
    func extractImageId() -> String? {
        // Example URL:
        // https://firebasestorage.googleapis.com/v0/b/gaggedapp.firebasestorage.app/o/images%2FB6E4FF4A-3655-4CBA-9770-102BF7ADA177.jpg?alt=media&token=abc
        
        guard let range = self.range(of: "images%2F") else { return nil }
        var idPart = String(self[range.upperBound...])
        
        // Cut off at .jpg
        if let endRange = idPart.range(of: ".jpg") {
            idPart = String(idPart[..<endRange.upperBound])
        }
        
        // Decode URL encoding (turn %2F → /)
        return idPart.removingPercentEncoding
    }
}

