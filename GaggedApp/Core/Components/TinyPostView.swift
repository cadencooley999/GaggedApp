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
    
    let post: PostModel
    let width: CGFloat?
    let height: CGFloat
    
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

                }

            }
            .frame(maxWidth: width != nil ? width : .infinity)
            VStack {
                HStack(spacing: 2) {
                    Spacer()
                    HStack {
                        HStack (spacing: 0) {
                            Text("\(1)")
                                .fontWeight(.bold)
                                .font(.caption2)
                                .foregroundColor(Color.theme.accent)
                            Image(systemName: "arrow.up")
                                .foregroundStyle(Color.theme.darkBlue)
                                .fontWeight(.bold)
                        }
                        HStack (spacing: 0){
                            Text("\(1)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                            Image(systemName: "arrow.down")
                                .foregroundStyle(Color.theme.darkRed)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(2)
                    .background(Color.theme.background.opacity(1).cornerRadius(10))
                    .frame(height: 15)
                }
                .padding(4)
                .frame(height: 20)
                Spacer()
                HStack(spacing: 2){
                    Text("\(post.name)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.accent)
                        .padding(4)
                        .background(Color.theme.background.opacity(1).cornerRadius(10))
                        .frame(height: 15)
                    Spacer()
                }
            }
            .padding(10)
            .padding(.vertical, 4)
            .frame(maxWidth: width != nil ? width : .infinity)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}
