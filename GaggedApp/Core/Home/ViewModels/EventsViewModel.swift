//
//  EventViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/24/25.
//

import Foundation
import SwiftUI

@MainActor
class EventsViewModel: ObservableObject {
    
    @Published var hasLoaded: Bool = false
    @Published var eventList: [EventModel] = []
    @Published var isLoading: Bool = false
    
    let storageManager = StorageManager.shared
    let eventManager = EventManager.shared
    
    func fetchEventsIfNeeded() async throws {
        guard !hasLoaded else {return}
        let events = try await eventManager.getEvents()
//        var posts = FirebasePostManager.shared.mockPosts
        eventList = events
        hasLoaded = true
    }
    func fetchMoreEvents() async throws {
        let events = try await eventManager.getEvents()
//        var posts = FirebasePostManager.shared.mockPosts
        eventList = events
    }

    
    func addRSVP(eventId: String) {
        for i in eventList.indices {
            if eventList[i].id == eventId {
                print("found and added")
                eventList[i].rsvps += 1
            }
        }
    }
    
    func removeRSVP(eventId: String) {
        for i in eventList.indices {
            if eventList[i].id == eventId {
                eventList[i].rsvps -= 1
            }
        }
    }
}

extension EventsViewModel {
    static func previewModel() -> EventsViewModel {
        let vm = EventsViewModel()
        return vm
    }
}


