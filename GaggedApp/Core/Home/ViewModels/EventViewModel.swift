//
//  EventViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/25/25.
//
//
//import Foundation
//import FirebaseFirestore
//import SwiftUI
//
//@MainActor
//final class EventViewModel: ObservableObject {
//    
//    @AppStorage("userId") var userId = ""
//    @AppStorage("username") var username = ""
//    
//    @Published var event: EventModel?
//    @Published var isRsvpd: Bool = false // change once we get authentication
//    @Published var comments: [viewCommentModel] = []
//    @Published var commentsIsLoading: Bool = false
//    @Published var eventsTransitionOffset: CGFloat = 0
    
    //    var eventManager = EventManager.shared
    //    var commentManager = CommentsManager.shared
    //    var coreDataManager = CoreDataManager.shared
    //
    //    func setEvent(event: EventModel) {
    //        self.event = event
    //    }
    //
    //    func fetchEvent(eventId: String) async throws -> EventModel {
    //        let event = try await eventManager.getEvent(id: eventId)
    //        return event
    //    }
    //
    //    func deleteEvent(eventId: String) async throws {
    //        guard eventId != "" else {
    //            return
    //        }
    //        try await eventManager.deleteEvent(eventId: eventId)
    //
    //    }
    //
    //    func rsvpForEvent(event: EventModel) {
    //        Task {
    //            self.event?.rsvps += 1
    //            try await eventManager.addRSVP(eventId: event.id)
    //        }
    //    }
    //
    //    func removeRsvp(event: EventModel) {
    //        func rsvpForEvent(event: EventModel) {
    //            Task {
    //                self.event?.rsvps -= 1
    //                try await eventManager.removeRSVP(eventId: event.id)
    //            }
    //        }
    //    }
    //
    //    func isSaved(eventId: String) async -> Bool {
    //        let posts = coreDataManager.getSavedPosts()
    //        print("posts: \(posts)")
    //        if posts.contains(where: {$0.id == eventId}) {
    //            return true
    //        }
    //        else {
    //            return false
    //        }
    //    }
    //
    //    func saveEvent(eventId: String) {
    //        coreDataManager.saveEvent(eventId: eventId)
    //        print("Saved")
    //    }
    //
    //    func unSaveEvent(eventId: String) {
    //        coreDataManager.deleteSaved(id: eventId)
    //        print("unSaved")
    //    }
    //
    //
    //    func upvoteCom(comId: String) {
    //        Task {
    //            comments[comments.firstIndex(where: {$0.id == comId}) ?? 0].comment.upvotes += 1
    //            try await commentManager.upvoteComment(commentId: comId)
    //        }
    //    }
    //
    //    func fetchComments() async throws {
    //        if let event = event {
    //            print("Fetching Comments")
    //            let coms = try await commentManager.getComments(postId: event.id)
    //            let viewComs = mapComments(comments: coms, layer: 0)
    //            comments = orderComments(comments: viewComs)
    //        }
    //    }
    //
    //    func mapComments(comments: [CommentModel], layer: Int) -> [viewCommentModel] {
    //        var finalComs: [viewCommentModel] = []
    //        for c in comments {
    //            finalComs.append(viewCommentModel(comment: c, isExpanded: false, id: c.id, indentLayer: getIndentLayer(com: c), numChildren: getNumChildren(com: c, comments: comments), isGrandchild: layer > 0 ? true : false))
    //        }
    //        return finalComs
    //    }
    //
    //    func getNumChildren(com: CommentModel, comments: [CommentModel]) -> Int {
    //        guard com.hasChildren else {return 0}
    //
    //        return comments.count(where: {$0.parentCommentId == com.id})
    //    }
    //
    //    func getNumChildren2(com: CommentModel, comments: [viewCommentModel]) -> Int {
    //        guard com.hasChildren else {return 0}
    //
    //        return comments.count(where: {$0.comment.parentCommentId == com.id})
    //    }
    //
    //    @MainActor
    //    func fetchChildren(viewComment: viewCommentModel, limit: Int = 0) async throws -> [viewCommentModel] {
    //        guard limit < 10 else { return [] }
    //        guard let event = event else { return [] }
    //
    //        // Fetch direct children
    //        let childComms = try await commentManager.getChildComments(postId: event.id, commentId: viewComment.id)
    //        var newChildComs = mapComments(comments: childComms, layer: limit)
    //        newChildComs = orderComments(comments: newChildComs)
    //
    //        var allChildren: [viewCommentModel] = []
    //
    //        for var child in newChildComs {
    //            // Recursively fetch deeper children if needed
    //            if child.comment.hasChildren {
    //                print("Fetching children in recursion")
    //                let grandchildren = try await fetchChildren(viewComment: child, limit: limit + 1)
    //                allChildren.append(child)
    //                allChildren.append(contentsOf: grandchildren)
    //            } else {
    //                allChildren.append(child)
    //            }
    //        }
    //
    //        print("ALL CHILDREN: ", allChildren)
    //
    //        return allChildren
    //    }
    //
    //    @MainActor
    //    func catchChildren(viewCom: viewCommentModel) async throws {
    //        do {
    //            let theChildren = try await fetchChildren(viewComment: viewCom)
    //            assignChildren(firstCom: viewCom, commentList: theChildren)
    //            comments = comments
    //        } catch {
    //            print("Error fetching children: \(error)")
    //        }
    //    }
    //
    //    @MainActor
    //    func assignChildren(firstCom: viewCommentModel, commentList: [viewCommentModel]) {
    //        guard let parentIndex = comments.firstIndex(where: { $0.id == firstCom.id }) else {
    //            comments.append(contentsOf: commentList)
    //            return
    //        }
    //
    //        comments.insert(contentsOf: commentList, at: parentIndex + 1)
    //        comments[parentIndex].isExpanded = true
    //        comments[parentIndex].numChildren = commentList.count
    //    }
    //
    //
    //    func getAuthor(id: String) -> String? {
    //        return comments.first(where: {$0.id == id})?.comment.authorId
    //    }
    //
    //    func collapseComments(viewComment: viewCommentModel) {
    //        comments.removeAll(where: {$0.comment.parentCommentId == viewComment.id})
    //        if let index = comments.firstIndex(where: {$0.id == viewComment.id}) {
    //            comments[index].isExpanded = false
    //        }
    //    }
    //
    //    func uploadComment(message: String, parentId: String?) async throws {
    //        if let event = event {
    //            let newComment = CommentModel(id: UUID().uuidString, postId: event.id, postName: event.name, authorName: username, message: message, authorId: userId, createdAt: Timestamp(date: Date()), upvotes: 0, parentCommentId: parentId ?? "", hasChildren: false, isOnEvent: true)
    //            if parentId != nil {
    //                try await commentManager.updateToParent(commentId: parentId!)
    //            }
    //            try await commentManager.uploadComment(comment: newComment)
    //        }
    //    }
    //
    //    func hasParent(id: String) -> Bool {
    //        if comments.first(where: {$0.id == id})?.comment.parentCommentId != "" {
    //            return true
    //        }
    //        return false
    //    }
    //
    //    func getIndentLayer(com: CommentModel) -> Int {
    //        print("Getting indent layer for \(com.id)")
    //        guard com.parentCommentId != "" else {
    //            print("Gaurded out")
    //            return 0
    //        }
    //
    //        var layer = 1
    //        var id = com.parentCommentId
    //        while true {
    //            if let parent = comments.first(where: {$0.comment.id == id}) {
    //                if parent.comment.parentCommentId == nil {
    //                    return layer
    //                }
    //                else {
    //                    layer += 1
    //                    id = parent.comment.parentCommentId!
    //                }
    //            }
    //            else {
    //                return layer
    //            }
    //        }
    //    }
    //
    //    func orderComments(comments: [viewCommentModel]) -> [viewCommentModel] {
    //        let now = Date()
    //        let nowSeconds = now.timeIntervalSince1970
    //
    //        return comments.sorted { (a: viewCommentModel, b: viewCommentModel) -> Bool in
    //            // Convert timestamps to seconds since 1970
    //            let createdASeconds = a.comment.createdAt.dateValue().timeIntervalSince1970
    //            let createdBSeconds = b.comment.createdAt.dateValue().timeIntervalSince1970
    //
    //            // Compute ages in hours
    //            let ageA = (nowSeconds - createdASeconds) / 3600.0
    //            let ageB = (nowSeconds - createdBSeconds) / 3600.0
    //
    //            // Each factor explicitly typed as Double
    //            let upvoteA = Double(a.comment.upvotes) * 1.0
    //            let upvoteB = Double(b.comment.upvotes) * 1.0
    //
    //            let childrenA = Double(a.numChildren) * 0.75
    //            let childrenB = Double(b.numChildren) * 0.75
    //
    //            let recencyA = -ageA * 0.5
    //            let recencyB = -ageB * 0.5
    //
    //            let weightA = upvoteA + childrenA + recencyA
    //            let weightB = upvoteB + childrenB + recencyB
    //
    //            return weightA > weightB
    //        }
    //    }
    //
    //    func timeAgoString(from timestamp: Timestamp) -> String {
    //        let date = timestamp.dateValue()
    //        let secondsAgo = Int(Date().timeIntervalSince(date))
    //
    //        let minute = 60
    //        let hour = 60 * minute
    //        let day = 24 * hour
    //        let month = 30 * day
    //        let year = 12 * month
    //
    //        if secondsAgo < 5 {
    //            return "just now"
    //        } else if secondsAgo < minute {
    //            return "\(secondsAgo)s"
    //        } else if secondsAgo < hour {
    //            return "\(secondsAgo / minute)m"
    //        } else if secondsAgo < day {
    //            return "\(secondsAgo / hour)h"
    //        } else if secondsAgo < month {
    //            return "\(secondsAgo / day)d"
    //        } else if secondsAgo < year {
    //            return "\(secondsAgo / month)mo"
    //        } else {
    //            return "\(secondsAgo / year)yr"
    //        }
    //    }
    //
    //    func timeUntilString(from date: Date) -> String {
    //        let now = Date()
    //        let diff = date.timeIntervalSince(now)
    //        let absDiff = abs(diff)
    //
    //        let minutes = absDiff / 60
    //        let hours = minutes / 60
    //        let days = hours / 24
    //        let months = days / 30.44 // average month length
    //
    //        let isFuture = diff > 0
    //
    //        let unit: String
    //        let value: Int
    //
    //        if months >= 1 {
    //            value = Int(months.rounded())
    //            unit = "mo"
    //        } else if days >= 1 {
    //            value = Int(days.rounded())
    //            unit = "d"
    //        } else if hours >= 1 {
    //            value = Int(hours.rounded())
    //            unit = "h"
    //        } else {
    //            return "Today"
    //        }
    //
    //        return isFuture ? "in \(value)\(unit)" : "began \(value)\(unit) ago"
    //    }
    //
    //    func getDateString(_ date: Date) -> String {
    //        let formatter = DateFormatter()
    //        formatter.dateFormat = "MM/dd/yy, h:mm a" // e.g. "Oct 22, 2025 10:45 AM"
    //        return formatter.string(from: date)
    //    }
//}
