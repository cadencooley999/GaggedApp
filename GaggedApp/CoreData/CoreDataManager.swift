//
//  PersistenceController.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/6/25.
//


import Foundation
import CoreData


class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private let containerName = "SavedPostContainer" // your .xcdatamodeld name
    private let savedItemName = "SavedPost"
    private let votedItemName = "VotedPost"
    private let votedCommentName = "VotedComment"
    
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Init
    private init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error)")
            }
        }
    }
    
    func getSavedPosts() -> [SavedPost] {
        let context = container.viewContext
        let request = NSFetchRequest<SavedPost>(entityName: savedItemName)
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
    }
//    
//    func saveEvent(eventId: String) {
//        let context = container.newBackgroundContext()
//        context.perform {
//            let newItem = SavedPost(context: context)
//            newItem.id = eventId
//            newItem.isPost = false
//            do {
//                try context.save()
//                print("Item added")
//            } catch {
//                print("Error saving item: \(error)")
//            }
//        }
//    }
    
    func deleteSaved(id: String) {
        let context = container.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<SavedPost>(entityName: self.savedItemName)
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
    }
    
    func getVotedPost(withId id: String) -> VotedPost? {
        let request = NSFetchRequest<VotedPost>(entityName: votedItemName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Voted Post Not Found")
            return nil
        }
    }
    
    func getUpvotedPosts() -> [VotedPost] {
        let request = NSFetchRequest<VotedPost>(entityName: "VotedPost")
        request.predicate = NSPredicate(format: "isUpvoted == YES")

        return (try? container.viewContext.fetch(request)) ?? []
    }
        
    func saveVotedPost(id: String, isUpvoted: Bool) {
        let context = container.newBackgroundContext()
        context.perform {
            
            // If it already exists → update it instead of duplicating
            let request = NSFetchRequest<VotedPost>(entityName: self.votedItemName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            if let existing = try? context.fetch(request).first {
                existing.isUpvoted = isUpvoted
            } else {
                let newVote = VotedPost(context: context)
                newVote.id = id
                newVote.isUpvoted = isUpvoted
            }
            
            do { try context.save() }
            catch { print("❌ Error saving VotedPost: \(error)") }
        }
    }
    
    func removeVote(id: String) {
        let context = container.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<VotedPost>(entityName: self.votedItemName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            
            do {
                if let vote = try context.fetch(request).first {
                    context.delete(vote)
                    try context.save()
                }
            } catch {
                print("❌ Error deleting VotedPost: \(error)")
            }
        }
    }
    
    func getCommentVote(commentId: String) -> VotedComment? {
        let request = NSFetchRequest<VotedComment>(entityName: votedCommentName)
        request.predicate = NSPredicate(format: "commentId == %@", commentId)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Voted Post Not Found")
            return nil
        }
    }
    
    func getPostCommentVotes(postId: String) -> [VotedComment] {
        let request = NSFetchRequest<VotedComment>(entityName: "VotedComment")
        request.predicate = NSPredicate(format: "postId == %@", postId)

        return (try? container.viewContext.fetch(request)) ?? []
    }
    
    func addCommentVote(commentId: String, postId: String) {
        let context = container.newBackgroundContext()
        context.perform {

            let newVote = VotedComment(context: context)
            newVote.commentId = commentId
            newVote.postId = postId

            do { try context.save() }
            catch { print("❌ Error saving VotedPost: \(error)") }
        }
    }
    
    func removeCommentVote(commentId: String) {
        let context = container.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<VotedComment>(entityName: self.votedCommentName)
            request.predicate = NSPredicate(format: "commentId == %@", commentId)
            request.fetchLimit = 1
            
            do {
                if let vote = try context.fetch(request).first {
                    context.delete(vote)
                    try context.save()
                }
            } catch {
                print("❌ Error deleting VotedPost: \(error)")
            }
        }
    }
}
