//
//  ReportModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/26/26.
//
import Foundation
import SwiftUI
import Firebase

enum ReportContentType: String {
    case post = "post"
    case comment = "comment"
    case poll = "poll"
}

enum ReportReason: String {
    case hate = "hate"
    case inapropriate = "inappropriate"
    case spam = "spam"
    case communityGuidlines = "communityGuidlines"
    case other = "other"
}

enum ReportStatus: String {
    case pending
    case deleted
    case dismissed
}

struct ReportModel {
    let id: String
    let contentType: ReportContentType
    let contentId: String
    let contentAuthorId: String
    let reportAuthorId: String
    let reason: ReportReason
    let status: ReportStatus
    let createdAt: Timestamp?
}

struct preReportModel {
    let contentType: ReportContentType
    let contentId: String
    let contentAuthorId: String
    let reportAuthorId: String
}
