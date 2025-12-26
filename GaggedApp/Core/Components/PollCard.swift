//
//  PollCard.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/18/25.
//

import SwiftUI
import Foundation


struct PollCard: View {
    
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var feedStore: FeedStore
    
    let poll: PollModel
    let options: [PollOption]
    @State var optionChose: String = ""
    @State var optionsVotes: [Int] = []
    @State var totalVotes: Int = 0
    
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // TITLE
            Text(poll.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // CONTEXT (optional)
            if !poll.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                InlineExpandableText(
                    text: poll.context,
                    limit: 40
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            // OPTIONS
            VStack(spacing: 8) {
                ForEach(options.sorted(by: { $0.index < $1.index })) { option in

                    let votePercent: CGFloat =
                    totalVotes == 0
                        ? 0
                    : CGFloat(optionsVotes[option.index]) / CGFloat(totalVotes)

                    Button {
                        let previousChoice = optionChose
                        let newChoice = option.id

//                        // IMMEDIATE UI UPDATE
//                        withAnimation(.easeInOut(duration: 0.25)) {
//                            optionChose = (optionChose == option.id) ? "" : option.id
//                        }

                        Task {
                            do {
                                if previousChoice == "" {
                                    try await pollsViewModel.sendVote(
                                        pollId: poll.id,
                                        optionId: newChoice
                                    )
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        optionChose = newChoice
                                        optionsVotes[option.index] += 1
                                        totalVotes += 1
                                    }
                                } else if previousChoice == newChoice {
                                    try await pollsViewModel.removeVote(
                                        pollId: poll.id,
                                        optionId: newChoice
                                    )
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        optionChose = ""
                                        optionsVotes[option.index] -= 1
                                        totalVotes -= 1
                                    }
                                } else {
                                    try await pollsViewModel.switchVote(
                                        pollId: poll.id,
                                        oldOptionId: previousChoice,
                                        newOptionId: newChoice
                                    )
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if let index = options.firstIndex(where: {$0.id == previousChoice}) {
                                            optionChose = newChoice
                                            optionsVotes[option.index] += 1
                                            optionsVotes[index] -= 1
                                        }
                                    }
                                }
                            } catch {
                                // ROLLBACK ON FAILURE
                                withAnimation {
                                    optionChose = previousChoice
                                }
                            }
                        }
                    }
                    label: {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(lineWidth: 1)
                                    .foregroundStyle(optionChose == option.id ? Color.theme.darkBlue : Color.theme.lightGray.opacity(0.5))

                                // Fill
                                if optionChose != "" {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.theme.lightGray.opacity(0.5))
                                        .frame(width: min(max(geo.size.width * votePercent, 0), geo.size.width))
                                }

                                // Text
                                HStack {
                                    Text(option.text)
                                        .foregroundStyle(optionChose == option.id ? Color.theme.darkBlue : Color.theme.accent)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    if optionChose != "" {
                                        Text("\(Int(votePercent * 100))%")
                                            .font(.subheadline)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if poll.linkedPostId != "" {
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(Color.theme.orange)
                    Text(poll.linkedPostName)
                        .italic()
                        .foregroundStyle(Color.theme.orange)
                    Spacer()
                    Text("Total Votes: ")
                    Text("\(totalVotes)")
                }
                .onTapGesture {
                    if let index = feedStore.loadedPosts.firstIndex(where: { $0.id == poll.linkedPostId }) {
                        postLinkFunction(post: feedStore.loadedPosts[index])
                    }
                    else {
                        Task {
                            let post = try await homeViewModel.fetchPost(postId: poll.linkedPostId)
                            postLinkFunction(post: post)
                        }
                    }
                }
            }
                
        }
        .onAppear {
            optionChose = pollsViewModel.getPollChoice(pollId: poll.id)
            for option in options.sorted(by: {$0.index < $1.index}) {
                optionsVotes.append(option.voteCount)
            }
            totalVotes = poll.totalVotes
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
        .padding(.horizontal)
    }
    
    func displayedVoteCount(for option: PollOption) -> Int {
        guard optionChose != "" else { return option.voteCount }

        if option.id == optionChose {
            return option.voteCount + 1
        }

        if pollsViewModel.getPollChoice(pollId: poll.id) == option.id {
            return option.voteCount - 1
        }

        return option.voteCount
    }
    
    func postLinkFunction(post: PostModel) {
        selectedPost = post
        postViewModel.setPost(postSelection: post)
        withAnimation(.easeInOut(duration: 0.2)) {
            showPostView = true
        }
        Task {
            postViewModel.commentsIsLoading = true
            try await postViewModel.fetchComments()
            postViewModel.commentsIsLoading = false
        }
    }

}
