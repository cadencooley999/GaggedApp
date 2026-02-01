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
    
    @EnvironmentObject var windowSize: WindowSize
    
    func isOverflowing(
        username: String,
        availableWidth: CGFloat,
        upvotes: Int,
        downvotes: Int
    ) -> Bool {

        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let font = UIFont.systemFont(
            ofSize: baseFont.pointSize,
            weight: .semibold
        )
        
        let nameWidth = textWidth(
            username,
            font: font
        )

        let votesWidth = votePillWidth(up: upvotes, down: downvotes)

        return nameWidth + votesWidth > availableWidth
    }

    private let cornerRadius: CGFloat = 24

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

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
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)

                // MARK: - Bottom Info Bar
                if !isOverflowing(username: post.name, availableWidth: CGFloat((windowSize.size.width / 2) - 50), upvotes: post.upvotes, downvotes: post.downvotes) {
                    VStack(spacing: 0){
                        HStack(spacing: 0) {

                            // NAME — no wrapping, ellipses
                            Text(post.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundStyle(Color.theme.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer(minLength: 4)

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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .layoutPriority(1)
                        }
                        .padding(.horizontal, 14)
                        
                        if let city = CityManager.shared.getCity(id: post.cityIds.first ?? "") {
                            HStack(spacing: 0){
                                Text(city.city)
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.gray)
                                Spacer()
                            }
                            .padding(.bottom)
                            .padding(.horizontal, 14)
                        }
                    }
                }
                else {
                    VStack(alignment: .leading, spacing: 0){
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
                        .padding(.vertical, 4)
                        
                        Text(post.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(Color.theme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        
                        if let city = CityManager.shared.getCity(id: post.cityIds.first ?? "") {
                            HStack(spacing: 0){
                                Text(city.city)
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.gray)
                            }
                            .padding(.top, 4)
                            .padding(.bottom)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(height: post.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.theme.darkBlue, lineWidth: stroked == true ? 2 : 0)
        )
        .frame(maxWidth: width != nil ? width : .infinity)
        .transition(.opacity)
    }
    
    func textWidth(_ text: String, font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: attributes).width
    }
    
    func votePillWidth(up: Int, down: Int) -> CGFloat {
        let upText = "\(up)"
        let downText = "\(down)"
        
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let font = UIFont.systemFont(
            ofSize: baseFont.pointSize,
            weight: .semibold
        )

        let numberWidth = textWidth(upText, font: font) + textWidth(downText, font: font)

        return numberWidth + 40 // arrows + padding
    }
}
