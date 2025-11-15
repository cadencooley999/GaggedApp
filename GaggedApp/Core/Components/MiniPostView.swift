//
//  PostView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/2/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore
import Kingfisher

struct MiniPostView: View {
    
    let post: PostModel
    let width: CGFloat?
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geo in
//                    CachedImage(post.imageUrl) { image in
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: geo.size.width, height: geo.size.height)
//                            .clipped()
//                    } placeholder: {
//                        PulsingRectangle(duration: Double.random(in: 0.5...1.5))
//                            .frame(width: geo.size.width, height: geo.size.height)
//                    } failure: {
//                        PulsingRectangle(duration: Double.random(in: 0.5...1.5))
//                            .frame(width: geo.size.width, height: geo.size.height)
//                    }
                    miniPostImage(url: post.imageUrl, height: geo.size.height, width: geo.size.width)

                }
            }
            .frame(height: post.height)
            .frame(maxWidth: width != nil ? width : .infinity)
            VStack {
                Spacer()
                HStack(spacing: 2){
                    Text("\(post.name)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.accent)
                        .padding(6)
                        .background(Color.theme.background.opacity(1).cornerRadius(10))
                        .frame(height: 20)
                    Spacer()
                    HStack(spacing: 2) {
                        HStack (spacing: 0) {
                            Text("\(post.upvotes)")
                                .fontWeight(.bold)
                                .font(.caption)
                                .foregroundColor(Color.theme.accent)
                            Image(systemName: "arrow.up")
                                .foregroundStyle(Color.theme.darkBlue)
                                .fontWeight(.bold)
                        }
                        HStack (spacing: 0){
                            Text("\(post.downvotes)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                            Image(systemName: "arrow.down")
                                .foregroundStyle(Color.theme.darkRed)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(4)
                    .background(Color.theme.background.opacity(1).cornerRadius(10))
                    .frame(height: 20)
                }
            }
            .padding(10)
            .padding(.vertical, 4)
            .frame(maxWidth: width != nil ? width : .infinity)
        }
        .frame(height: post.height)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}

#Preview {
    MiniPostView(post: PostModel(id: "1234", text: "ASDF", name: "Benjamin", imageUrl: "", upvotes: 5, downvotes: 2, createdAt: Timestamp(date: Date()), authorId: "asf", authorName: "acasdf", height: 250, cityIds: ["ASDF"], cities: [], keywords: [], upvotesThisWeek: 3, lastUpvoted: Timestamp(date: Date())), width: 200)
}
