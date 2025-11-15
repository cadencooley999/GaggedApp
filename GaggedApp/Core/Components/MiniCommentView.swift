//
//  MiniCommentView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/3/25.
//

import SwiftUI
import FirebaseFirestore

struct MiniCommentView: View {
    
    let comment: CommentModel
    
    var body: some View {
        VStack(spacing: 2){
            HStack {
                Text(comment.message)
                    .padding(8)
                    .padding(.bottom, 4)
                    .background(Color.theme.lightGray.opacity(0.5))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 2){
                    Text("\(comment.upvotes)")
                    Image(systemName: "arrow.up")
                        .foregroundStyle(Color.theme.darkBlue)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding()
    }
    
}

#Preview {
    MiniCommentView(comment: CommentModel(id: "124", postId: "123", postName: "OgpostName", authorName: "Authornam", message: "This is a really nice comment", authorId: "caden", createdAt: Timestamp(date: Date()), upvotes: 2, parentCommentId: "12345", hasChildren: false, isOnEvent: false))
}
