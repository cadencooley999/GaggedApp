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

//struct MiniPostView: View {
//
//    let post: PostModel
//    let width: CGFloat?
//
//    @EnvironmentObject var homeViewModel: HomeViewModel
//
//    var body: some View {
//        ZStack {
//            ZStack {
//                Rectangle()
//                    .fill(Color.theme.darkBlue.opacity(0.1))
//                    .frame(height: post.height)
//                    .frame(maxWidth: width != nil ? width : .infinity)
//                VStack {
//                    GeometryReader { geo in
//                        miniPostImage(url: post.imageUrl, height: geo.size.height, width: geo.size.width)
//                    }
//                    .clipShape(RoundedRectangle(cornerRadius: 25))
//                    .padding(8)
//                    Spacer()
//                }
//
//            }
//            VStack {
//                Spacer()
//                HStack(spacing: 2){
//                    Text("\(post.name)")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                        .foregroundColor(Color.theme.accent)
//                        .padding(6)
//                        .background(Color.theme.background.opacity(1).cornerRadius(10))
//                        .frame(height: 20)
//                    Spacer()
//                    HStack(spacing: 2) {
//                        HStack (spacing: 0) {
//                            Text("\(post.upvotes)")
//                                .fontWeight(.bold)
//                                .font(.caption)
//                                .foregroundColor(Color.theme.accent)
//                            Image(systemName: "arrow.up")
//                                .foregroundStyle(Color.theme.darkBlue)
//                                .fontWeight(.bold)
//                        }
//                        HStack (spacing: 0){
//                            Text("\(post.downvotes)")
//                                .font(.caption)
//                                .fontWeight(.bold)
//                                .foregroundColor(Color.theme.accent)
//                            Image(systemName: "arrow.down")
//                                .foregroundStyle(Color.theme.darkRed)
//                                .fontWeight(.bold)
//                        }
//                    }
//                    .padding(4)
//                    .background(Color.theme.background.opacity(1).cornerRadius(10))
//                    .frame(height: 20)
//                }
//            }
//            .padding(10)
//            .padding(.vertical, 4)
//            .frame(maxWidth: width != nil ? width : .infinity)
//        }
//        .frame(height: post.height)
//        .clipShape(RoundedRectangle(cornerRadius: 25))
//    }
//}
struct MiniPostView: View {

    var post: PostModel
    let width: CGFloat?
    let stroked: Bool?

    private let cornerRadius: CGFloat = 22

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)

            VStack(spacing: 0) {

                // MARK: - Image
                GeometryReader { geo in
                    miniPostImage(
                        url: post.imageUrl,
                        height: geo.size.height,
                        width: geo.size.width
                    )
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 6))
                }
                .padding(12)
                .frame(maxWidth: .infinity)

                // MARK: - Bottom Info Bar
                HStack(spacing: 10) {

                    // NAME — no wrapping, ellipses
                    Text(post.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(Color.theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // VOTES
                    HStack(spacing: 4) {

                        HStack(spacing: 2) {
                            Text("\(post.upvotes)")
                            Image(systemName: "arrow.up")
                                .foregroundColor(Color.theme.darkBlue)
                        }
                        .font(.subheadline.bold())

                        HStack(spacing: 2) {
                            Text("\(post.downvotes)")
                            Image(systemName: "arrow.down")
                                .foregroundColor(Color.theme.darkRed)
                        }
                        .font(.subheadline.bold())

                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .frame(height: post.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.theme.orange, lineWidth: stroked == true ? 2 : 0)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        .frame(maxWidth: width != nil ? width : .infinity)
        .transition(.opacity)
    }
}
