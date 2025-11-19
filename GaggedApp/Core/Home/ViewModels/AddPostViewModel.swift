//
//  AddPostViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
import Combine

@MainActor
final class AddPostViewModel: ObservableObject {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""

    @Published var pickedImage: UIImage? = nil
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            print("did set")
            setImage(selection: imageSelection)
        }
    }
    @Published var citiesFound: [String] = []
    @Published var searchText: String = ""
    @Published var selectedCities: [String] = []
    
    let storageManager = StorageManager.shared
    let postManager = FirebasePostManager.shared
    let cityManager = CityManager.shared
    let eventManager = EventManager.shared
    
    var cancellables = Set<AnyCancellable>()

    init() {
        addSubscribers()
    }

    let heights: [CGFloat] = [220]
    
    func addSubscribers() {
        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                if self.searchText == "" {
                    Task {
                       self.fetchAllCities()
                    }
                }
                else {
                    self.searchCities(keyword: self.searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    func uploadNewPost(text: String, name: String, image: UIImage, cityIds: [String]) async throws -> Bool {
        do {
            let authorId = userId
            let imageId = UUID().uuidString
            
            let imageUrl = try await storageManager.uploadImage(image, imageId: imageId)
            
            let post = PostModel(id: "", text: text, name: name, imageUrl: imageUrl, upvotes: 0, downvotes: 0, createdAt: Timestamp(date: Date()), authorId: authorId, authorName: username, height: 120, cityIds: cityIds, keywords: [], upvotesThisWeek: 0, lastUpvoted: nil)
            try await postManager.uploadPost(post: post)
            print("✅ Success")
            return true
        } catch {
            print("❌ Failed with error: \(error.localizedDescription)")
            return false
        }
    }
    
    func uploadNewEvent(description: String, name: String, image: UIImage?, rsvps: Int, cityId: String, locationDetails: String, date: Date) async throws -> Bool {
        do {
            var imageUrl = ""
            var imageId = UUID().uuidString
            if let image = image {
                imageUrl = try await storageManager.uploadImage(image, imageId: imageId)
            }
            let event = EventModel(id: "", name: name, locationDetails: locationDetails, date: date, rsvps: rsvps, imageUrl: imageUrl, description: description, authorId: userId, authorName: username, cityId: cityId, keywords: [])
            try await eventManager.uploadEvent(event: event)
            print("Success uploading event")
            return true
        } catch {
            print("Failed with error: \(error.localizedDescription)")
            return false
        }
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
    
    func searchCities(keyword: String) {
        Task {

        }
    }
    
    func fetchAllCities() {
        Task {

        }
    }
}
