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
    @Published var searchText: String = ""
    @Published var selectedCities: [City] = []
    @Published var query: String = ""
    @Published var filteredCities: [City] = []
    
    let storageManager = StorageManager.shared
    let postManager = FirebasePostManager.shared
    let cityManager = CityManager.shared
    let eventManager = EventManager.shared
    let pollManager = PollManager.shared
    
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(120), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.searchCities()
            }
            .store(in: &cancellables)
    }

    let heights: [CGFloat] = [220]
    
    func searchCities() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if q.isEmpty {
            filteredCities = Array(CityManager.shared.allCities.prefix(50))
            return
        }

        Task.detached { [query = q] in
            // Safely fetch cities from main actor
            let cities = await CityManager.shared.allCities
            
            // Filter
            let filtered = cities.filter { city in
                city.city.localizedCaseInsensitiveContains(query)
            }

            // Limit results without mutating
            let limited = filtered.count > 100
                ? Array(filtered.prefix(100))
                : filtered

            // Send back to UI
            await MainActor.run {
                self.filteredCities = limited
            }
        }
    }
    
    func uploadNewPost(text: String, name: String, image: UIImage, cityIds: [String]) async throws -> Bool {
        do {
            let authorId = userId
            let imageId = UUID().uuidString
            
            let imageUrl = try await storageManager.uploadImage(image, imageId: imageId)
            
            let post = PostModel(id: "", text: text, name: name, imageUrl: imageUrl, createdAt: Timestamp(date: Date()), authorId: authorId, height: 120, cityIds: cityIds, keywords: [], upvotes: 0, downvotes: 0)
            try await postManager.uploadPost(post: post)
            print("✅ Success")
            return true
        } catch {
            print("❌ Failed with error: \(error.localizedDescription)")
            return false
        }
    }
    
    func uploadNewPoll(title: String, context: String, options: [String], cityId: String) async throws -> Bool {
        do {
            let newPoll = PollModel(id: "", authorId: userId, title: title, context: context, postId: "", optionsCount: options.count, totalVotes: 0, createdAt: Timestamp(date: Date()), cityId: cityId, keywords: [])
            var pollOptions: [PollOption] = []
            for (index, option) in options.enumerated() {
                pollOptions.append(PollOption(id: "", text: option, voteCount: 0, index: index))
            }
            try await pollManager.addPoll(poll: newPoll, options: pollOptions)
            return true
        }
        catch {
            print(error)
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
}
