//
//  SearchView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//

import SwiftUI
import Foundation

struct SearchView: View {
    
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    
    @FocusState var isFocused: Bool
    @Binding var showSearchView: Bool
    @Binding var hideTabBar: Bool
    @Binding var showPostView: Bool
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            ScrollView {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<searchViewModel.columns, id: \.self) { columnIndex in
                        columnView(for: columnIndex)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 64)
            }
            .onScrollPhaseChange({ oldPhase, newPhase in
                if newPhase == .interacting {
                    UIApplication.shared.endEditing()
                }
            })
            VStack(spacing: 0){
                header
                    .frame(height: 55)
                    .background(Color.theme.background.ignoresSafeArea())
                Spacer()
            }
        }
        .highPriorityGesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 { // left swipe
                        UIApplication.shared.endEditing()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchView = false
                            hideTabBar = false
                        }
                        searchViewModel.searchText = ""
                    }
                }
        )
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                isFocused = true
            })
        }
    }
    
    
    var header: some View {
        VStack(spacing: 0){
            HStack {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .onTapGesture {
                        print("CHEV TAPPED")
                        UIApplication.shared.endEditing()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchView = false
                            hideTabBar = false
                        }
                        searchViewModel.searchText = ""
                    }
                    .padding(.horizontal)
                Spacer()
                TextField("Search posts...", text: $searchViewModel.searchText)
                    .focused($isFocused)
            }
            .padding()
            Divider()
        }

    }
    
    @ViewBuilder
    private func columnView(for index: Int) -> some View {
        VStack {
            if searchViewModel.postMatrix.indices.contains(index),
               !searchViewModel.postMatrix[index].isEmpty {

                ForEach(searchViewModel.postMatrix[index]) { post in
                    MiniPostView(post: post, width: nil)
                        .onTapGesture {
                            handlePostTap(post)
                        }
                }
                Spacer()
            }
        }
    }
    
    private func handlePostTap(_ post: PostModel) {
        postViewModel.setPost(postSelection: post)
        hideTabBar = true
        UIApplication.shared.endEditing()
        showPostView = true
        Task {
            postViewModel.commentsIsLoading = true
            try await postViewModel.fetchComments()
            postViewModel.commentsIsLoading = false
        }
    }
    
//    var resultsSection: some View {
//        HStack {
//            ForEach(0..<searchViewModel.columns, id: \.self) { x in
//                VStack {
//                    if searchViewModel.postMatrix.indices.contains(x) {
//                        if !searchViewModel.postMatrix[x].isEmpty {
//                            ForEach(searchViewModel.postMatrix[x]) { post in
//                                MiniPostView(post: post)
//                                    .onTapGesture {
//                                        searchViewModel.setPost(postSelection: post)
//                                        hideTabBar = true
//                                        showPostView = true
//                                        Task {
//                                            postViewModel.commentsIsLoading = true
//                                            try await postViewModel.fetchComments()
//                                            postViewModel.commentsIsLoading = false
//                                        }
//                                    }
//                            }
//                            Spacer()
//                        }
//                    }
//                }
//            }
//        }
//    }
}

#Preview {
    SearchView(showSearchView: .constant(true), hideTabBar: .constant(true), showPostView: .constant(false))
        .environmentObject(SearchViewModel())
        .environmentObject(PostViewModel())
}
