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

enum AddPostError: Error {
    case imageUploadFailed
}

@MainActor
final class AddPostViewModel: ObservableObject {
    
    @AppStorage("userId") var userId = ""
    @AppStorage("username") var username = ""
    @AppStorage("chosenProfileImageAddress") var profImageUrl = ""
    
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
    @Published var selectedTags: [TagModel] = []
    @Published var currentNewContent: NewContent = .post
    @Published var linkedPost: PostModel? = nil
    
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
            let postRef = Firestore.firestore().collection("Posts").document()
            
            let post = PostModel(id: "", text: text, name: name, imageUrl: "", createdAt: Timestamp(date: Date()), authorId: authorId, authorName: username, authorPicUrl: profImageUrl, height: 120, cityIds: cityIds, tags: selectedTags.map({$0.title}), keywords: [], upvotes: 0, downvotes: 0)
            
            try await postManager.uploadPost(post: post, postRef: postRef)
            
            let urlString = try await uploadWithRetries(call: {
                try await self.storageManager.uploadImage(image, imageId: imageId, userId: self.userId, postId: postRef.documentID)
            })
            
            if let urlString = urlString {
                try await postManager.finalizePost(postId: postRef.documentID, imageUrl: urlString)
                print("Post Finalized")
            }
            print(post.name, "postname")
            UserManager.shared.addGags(userId: userId, contributionType: .post)
            return true
        } catch {
            print("❌ Failed with error: \(error.localizedDescription)")
            return false
        }
    }
    
    func uploadNewPoll(title: String, context: String, options: [String], cityId: String, linkedPostId: String, linkedPostName: String) async throws -> Bool {
        do {
            let newPoll = PollModel(id: "", authorId: userId, authorName: username, authorPicUrl: profImageUrl, title: title, context: context, linkedPostId: linkedPostId, linkedPostName: linkedPostName, optionsCount: options.count, totalVotes: 0, createdAt: Timestamp(date: Date()), cityId: cityId, keywords: [])
            var pollOptions: [PollOption] = []
            for (index, option) in options.enumerated() {
                pollOptions.append(PollOption(id: "", text: option, voteCount: 0, index: index))
            }
            try await pollManager.addPoll(poll: newPoll, options: pollOptions)
            UserManager.shared.addGags(userId: userId, contributionType: .poll)
            return true
        }
        catch {
            print(error)
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
    
    func uploadWithRetries(retries: Int = 3, delay: Double = 1.0, call: @escaping () async throws -> String) async throws -> String? {
        
        var attempt = 0
        
        while attempt < retries {
            do {
                var url = try await call()
                return url
            } catch {
                attempt += 1
                try? await Task.sleep(nanoseconds: UInt64(delay * 1000_000_000))
            }
        }
        
        throw AddPostError.imageUploadFailed
    }
}
