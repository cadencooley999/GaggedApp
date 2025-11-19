//
//  EventManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/23/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

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
            "city" : try Firestore.Encoder().encode(event.city),
            "cityId" : event.cityId,
            "rsvps" : event.rsvps,
            "locationDetails" : event.locationDetails,
            "keywords" : generateKeywords(name: event.name, authorName: event.authorName)
        ])
    }
    
    func getEvents() async throws -> [EventModel] {
        
        var events: [EventModel] = []
        
        let query: Query = eventsCollection.limit(to: 20)
        let newDocs = try await query.getDocuments()
                                        
        for i in newDocs.documents {
              let post = mapEvent(doc: i)
              events.append(post)
          }
        
        return events
    }
    
    func getEvent(id: String) async throws -> EventModel {
        let doc = try await eventsCollection.document(id).getDocument()
        return mapEvent(doc: doc)
    }
    
    func deleteEvent(eventId: String) async throws {
        let eventRef = eventsCollection.document(eventId)
        try await eventRef.delete()
    }
    
    func getUserEvents(uid: String) async throws -> [EventModel] {
        
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
        var events: [EventModel] = []
        for id in ids {
            let doc = try await eventsCollection.document(id).getDocument()
            let newitem = mapEvent(doc: doc)
            events.append(newitem)
        }
        return events
    }
    
    func getEventsFromSearch(keyword: String) async throws -> [EventModel] {
        
        var events: [EventModel] = []
        var newkeyword = keyword
        
        if keyword.contains(" ") {
            newkeyword = newkeyword.replacingOccurrences(of: " ", with: "")
        }
        
        do {
            let querySnapshot = try await eventsCollection.whereField("keywords", arrayContains: keyword.lowercased()).limit(to: 30).getDocuments()
              for document in querySnapshot.documents {
                  let newitem =  mapEvent(doc: document)
                  events.append(newitem)
              }
        } catch {
          print("Error getting documents: \(error)")
        }
        
        return events
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
        try await eventsCollection.document(eventId).updateData([
            "rsvps": FieldValue.increment(Int64(1))
        ])
    }
    
    func removeRSVP(eventId: String) async throws {
        try await eventsCollection.document(eventId).updateData([
            "rsvps": FieldValue.increment(Int64(-1))
        ])
    }
}

