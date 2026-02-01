//
//  EventManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/23/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

enum EventManagerError: Error { case invalidId, invalidCityIds, documentNotFound }

class EventManager {
    
    static let shared = EventManager()
    
    private var eventsCollection: CollectionReference {
        Firestore.firestore().collection("Events")
    }
    
    func uploadEvent(event: EventModel) async throws {
        
        let eventRef = eventsCollection.document()
        let eventId = eventRef.documentID
        let timestamp: Timestamp = Timestamp(date: event.date)
        
        try await eventRef.setData([
            "id": eventId,
            "description": event.description,
            "imageUrl": event.imageUrl,
            "authorId": event.authorId,
            "authorName" : event.authorName,
            "name" : event.name,
            "date" : timestamp,
            "cityId" : event.cityId,
            "rsvps" : event.rsvps,
            "locationDetails" : event.locationDetails,
            "keywords" : generateKeywords(name: event.name, authorName: event.authorName)
        ])
    }
    
    func getEvents(from cityIds: [String]) async throws -> [EventModel] {
        
        guard !cityIds.isEmpty else { return [] }
        
        let batches = cityIds.chunked(into: 10)
        
        print(cityIds)
        
        var allEvents: [EventModel] = []
        var seen: Set<String> = []   // Avoid duplicate posts
        
        for batch in batches {
            let query = eventsCollection
                .whereField("cityId", in: (batch))
                .limit(to: 20)
            
            let snapshot = try await query.getDocuments()
            
            for doc in snapshot.documents {
                let event = mapEvent(doc: doc)
                
                // Avoid duplicates if multiple batches matched it
                if seen.insert(event.id).inserted {
                    allEvents.append(event)
                }
            }
        }
        
        return allEvents
    }
    
    func getEvent(id: String) async throws -> EventModel {
        guard !id.isEmpty else { throw EventManagerError.invalidId }
        let doc = try await eventsCollection.document(id).getDocument()
        guard doc.exists else { throw EventManagerError.documentNotFound }
        return mapEvent(doc: doc)
    }
    
    func deleteEvent(eventId: String) async throws {
        guard !eventId.isEmpty else { throw EventManagerError.invalidId }
        let ref = eventsCollection.document(eventId)
        let snap = try await ref.getDocument()
        guard snap.exists else { return }
        try await ref.delete()
    }
    
    func getUserEvents(uid: String) async throws -> [EventModel] {
        guard !uid.isEmpty else { return [] }
        
        var events: [EventModel] = []
        
        let query: Query = eventsCollection.whereField("authorId", isEqualTo: uid).order(by: "date", descending: true).limit(to: 20)
        let newDocs = try await query.getDocuments()
        
        for i in newDocs.documents {
            var event = mapEvent(doc: i)
            events.append(event)
        }
        
        return events
        
    }
    
    func getEventsFromIds(ids: [String]) async throws -> [EventModel] {
        guard !ids.isEmpty else { return [] }
        var events: [EventModel] = []
        for id in ids {
            guard !id.isEmpty else { continue }
            let doc = try await eventsCollection.document(id).getDocument()
            guard doc.exists else { continue }
            let newitem = mapEvent(doc: doc)
            events.append(newitem)
        }
        return events
    }
    
    func getEventsFromSearch(keyword: String, allEventsNearby: [EventModel]) async throws -> [EventModel] {
        
        return allEventsNearby.filter { event in
            let lower = keyword.lowercased()

            // 1. Match post name
            if event.name.lowercased().contains(lower) { return true }

            // 2. Match author
            if event.authorName.lowercased().contains(lower) { return true }

            // 3. Match city names
            let cities = CityManager.shared.getCities(ids: [event.cityId])
            if cities.contains(where: { $0.city.lowercased().contains(lower) }) {
                return true
            }

            return false
        }
    }
    
    
    func getAllEventsNearby(cities: [String]) async throws -> [EventModel] {
        guard !cities.isEmpty else { return [] }
        var results: [EventModel] = []
        var seen: Set<String> = []

        let chunks = cities.chunked(into: 10)

        for chunk in chunks {
            let query = eventsCollection
                .whereField("cityId", in: chunk)

            let snapshot = try await query.getDocuments()
            for doc in snapshot.documents {
                let event = mapEvent(doc: doc)
                if seen.insert(event.id).inserted {
                    results.append(event)
                }
            }
        }
        return results
    }
    
    private func mapEvent(doc: DocumentSnapshot) -> EventModel {
        let id = doc["id"] as? String ?? ""
        let description = doc["description"] as? String ?? "no description"
        let timestamp = doc["date"] as? Timestamp
        let date = timestamp?.dateValue() ?? Date()
        let name = doc["name"] as? String ?? "No name"
        let imageUrl = doc["imageUrl"] as? String ?? ""
        let rsvps = doc["rsvps"] as? Int ?? 0
        let locationDetails = doc["locationDetails"] as? String ?? ""
        let authorId = doc["authorId"] as? String ?? ""
        let authorName = doc["authorName"] as? String ?? ""
        let keywords = doc["keywords"] as? [String] ?? []
        let cityId = doc["cityId"] as? String ?? ""

        
        return EventModel(id: id, name: name, locationDetails: locationDetails, date: date, rsvps: rsvps, imageUrl: imageUrl, description: description, authorId: authorId, authorName: authorName, cityId: cityId, keywords: keywords)
    }
    
    func generateKeywords(name: String, authorName: String) -> [String] {
        let inputs = [name, authorName]
        
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
    
    func addRSVP(eventId: String) async throws {
        guard !eventId.isEmpty else { throw EventManagerError.invalidId }
        let ref = eventsCollection.document(eventId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw EventManagerError.documentNotFound }
        try await ref.updateData([
            "rsvps": FieldValue.increment(Int64(1))
        ])
    }
    
    func removeRSVP(eventId: String) async throws {
        guard !eventId.isEmpty else { throw EventManagerError.invalidId }
        let ref = eventsCollection.document(eventId)
        let snap = try await ref.getDocument()
        guard snap.exists else { throw EventManagerError.documentNotFound }
        try await ref.updateData([
            "rsvps": FieldValue.increment(Int64(-1))
        ])
    }
}

