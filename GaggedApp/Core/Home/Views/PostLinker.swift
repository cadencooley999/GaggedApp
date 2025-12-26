//
//  OneSearch.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/1/25.
//

import SwiftUI
import Foundation

struct PostLinker: View {
    
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @FocusState var isFocused: Bool
    
    @Binding var linkedPost: PostModel?
    
    @State var postToLink: PostModel? = nil
    
    @Binding var showPostPicker: Bool
    
    @Namespace private var segmentedSwitch
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            if searchViewModel.isLoading {
                CircularLoadingView(color: Color.theme.darkBlue)
                    .frame(width: 30, height: 30)
            }
            ScrollView {
                VStack {
                    header
                        .frame(height: 55)
                    contentFeed(currentFilter: searchViewModel.selectedFilter)
                        .padding(.top, 5    )
                }
                .padding()
            }
            .onScrollPhaseChange({ oldPhase, newPhase in
                if newPhase == .interacting {
                    UIApplication.shared.endEditing()
                }
            })
            VStack {
                Spacer()
                attachButton
            }
            .padding()
        }
        .edgesIgnoringSafeArea(.bottom)
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                searchViewModel.addSubscribers {
                    locationManager.citiesInRange
                }
                isFocused = true
            })
        }
    }
    
    var attachButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 100, height: 50)
                .foregroundStyle(Color.theme.orange.opacity(postToLink == nil ? 0.3 : 1.0))
            Text("Attach")
                .font(.headline)
                .foregroundStyle(Color.theme.white)
        }
        .onTapGesture {
            if postToLink != nil {
                linkedPost = postToLink
                UIApplication.shared.endEditing()
                showPostPicker = false
            }
        }
    }
    
    var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title3)
                .onTapGesture {
                    showPostPicker = false
                }
            HStack(spacing: 8) {

                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundStyle(.secondary)

                TextField("Search Posts...", text: $searchViewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Color.theme.lightGray
                    .opacity(0.2)
                    .cornerRadius(16)
            )
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder func contentFeed(currentFilter: SearchFilter) -> some View {
        ZStack {
            postFeed
        }
    }
    
    var postFeed: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            HStack {
                ForEach(0..<searchViewModel.columns) { x in
                    VStack {
                        if searchViewModel.postMatrix.indices.contains(x) {
                            if !searchViewModel.postMatrix[x].isEmpty {
                                ForEach(searchViewModel.postMatrix[x], id: \.self) { post in
                                    MiniPostView(post: post, width: nil, stroked: post.id == postToLink?.id)
                                        .id("\(post.id)-\(post.upvotes)-\(post.downvotes)")
                                        .contentShape(Rectangle())
                                        .transition(.opacity)
                                        .onTapGesture {
                                            postToLink = post
                                        }
                                        
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }

        }
    }
}

