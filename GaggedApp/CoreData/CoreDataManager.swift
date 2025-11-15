//
//  PersistenceController.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/6/25.
//


import Foundation
import CoreData

class CoreDataManager {
    
    private let container: NSPersistentContainer
    private let containerName: String = "SavedPostContainer"
    private let itemName: String = "SavedPost"
    
    static let shared = CoreDataManager()
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error with core data \(error)")
            }
        }
    }
    
    func getSavedPosts() -> [SavedPost] {
        let context = container.viewContext
        let request = NSFetchRequest<SavedPost>(entityName: itemName)
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching posts: \(error)")
            return []
        }
    }
    
    func savePost(postId: String) {
        let context = container.newBackgroundContext()
        context.perform {
            let newItem = SavedPost(context: context)
            newItem.id = postId
            newItem.isPost = true
            do {
                try context.save()
                print("Item added")
            } catch {
                print("Error saving item: \(error)")
            }
        }
        
        /// + add to firebase
    }
    
    func saveEvent(eventId: String) {
        let context = container.newBackgroundContext()
        context.perform {
            let newItem = SavedPost(context: context)
            newItem.id = eventId
            newItem.isPost = false
            do {
                try context.save()
                print("Item added")
            } catch {
                print("Error saving item: \(error)")
            }
        }
        
        /// + add to firebase
    }
    
    func deleteSaved(id: String) {
        let context = container.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<SavedPost>(entityName: self.itemName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            do {
                if let item = try context.fetch(request).first {
                    context.delete(item)
                    try context.save()
                    print("Item deleted")
                }
            } catch {
                print("Error deleting item: \(error)")
            }
        }
        
        //// + delete from firebase
    }
    
}
