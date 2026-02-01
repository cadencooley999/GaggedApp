//
//  TinyPostView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/2/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct TinyPostView: View {

    var post: PostModel
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            miniPostImage(
                url: post.imageUrl,
                height: height,
                width: width
            )
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 25))
            
            VStack {
                Spacer()
                Text(post.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(8)
                    .padding(.horizontal, 2)
                    .glassEffect()
            }
            .frame(maxWidth: width, alignment: .leading)
            .padding(8)
        }
        .frame(width: width, height: height)
    }
}
