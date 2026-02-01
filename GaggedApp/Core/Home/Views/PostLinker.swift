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
            Color(.systemGroupedBackground)
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
        }
        .edgesIgnoringSafeArea(.bottom)
        .task {
            print("postlinkertask")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                searchViewModel.addSubscribers {
                    locationManager.citiesInRange
                }
                isFocused = true
            })
        }
    }
    
    var attachButton: some View {
        let isEnabled = postToLink != nil
        return HStack {
            Image(systemName: "link")
            Text("Attach")
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(12)
        .glassEffect(.regular.tint(Color.theme.darkBlue), in: .rect(cornerRadius: 16))
        .glassEffectTransition(.materialize)
        .onTapGesture {
            guard isEnabled else { return }
            linkedPost = postToLink
            UIApplication.shared.endEditing()
            showPostPicker = false
        }
    }
    
    var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundStyle(Color.theme.gray)
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
                    .focused($isFocused)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .glassEffectTransition(.identity)
            if postToLink != nil {
                attachButton
            }
        }
    }
    
    @ViewBuilder func contentFeed(currentFilter: SearchFilter) -> some View {
        ZStack {
            postFeed
        }
    }
    
    var postFeed: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
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
                                            withAnimation(.easeInOut(duration: 0.4)) {
                                                if postToLink == post {
                                                    postToLink = nil
                                                } else {
                                                    postToLink = post
                                                }
                                            }
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

