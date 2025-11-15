//
//  ImageManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/5/25.
//

import Foundation
import Kingfisher
import SwiftUI

struct miniPostImage: View {
    
    let url: String
    let height: CGFloat
    let width: CGFloat
    @State var isLoading: Bool = true
    @State var isFailed: Bool = false
    
    var body: some View {
        ZStack {
            KFImage(URL(string: url))
                .onFailure { error in
                    isFailed = true
                }
                .placeholder {
                    PulsingRectangle(duration: Double.random(in: 0.5...1.5))
                        .frame(width: width, height: height)
                }
                .onSuccess { _ in
                    isLoading = false
                }
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .onAppear {
                    isLoading = true
                }
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                PulsingRectangle(duration: Double.random(in: 0.5...1.5))
                    .frame(width: width, height: height)
            }
            if isFailed {
                PulsingRectangle(duration: Double.random(in: 0.5...1.5))
                    .frame(width: width, height: height)
            }
        }
    }
}

struct postImage: View {
    let url: String
    let maxHeight: CGFloat
    @State var isLoading: Bool = true
    @State var isFailed: Bool = false
    
    var body: some View {
        ZStack {
            KFImage(URL(string: url))
                .onFailure { error in
                    isFailed = true
                }
                .placeholder {
                    ZStack {
                        ProgressView()
                            .scaledToFill()
                    }
                    .frame(height: 350)
                }
                .onSuccess { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoading = false
                    }
                }
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                .clipped()
                .onAppear {
                    isLoading = true
                }
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ZStack {
                    ProgressView()
                        .scaledToFill()
                }
                .frame(height: 350)
            }
            if isFailed {
                ZStack {
                    ProgressView()
                        .scaledToFill()
                }
                .frame(height: 350)
            }
        }
    }
}

struct profileImageClip: View {
    let url: String
    let height: CGFloat
    @State var isLoading: Bool = false
    @State var isFailed: Bool = false
    
    var body: some View {
        ZStack {
            KFImage(URL(string: url))
                .onFailure { error in
                    isFailed = true
                }
                .placeholder {
                    Image("blank-profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: height, height: height)
                        .clipShape(Circle())
                }
                .onSuccess { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoading = false
                    }
                }
                .resizable()
                .scaledToFill()
                .frame(width: height, height: height)
                .clipShape(Circle())
                .onAppear {
                    
                }
                .overlay {
                    if isLoading || isFailed {
                        Image("blank-profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: height, height: height)
                            .clipShape(Circle())
                    }
                }
        }
    }
}



