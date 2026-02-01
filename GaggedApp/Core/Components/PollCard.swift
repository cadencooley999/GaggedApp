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
    
    @State var showOptionsSheet: Bool = false
    @State var selectedItemForOptions: GenericItem? = nil
    
    private let cornerRadius: CGFloat = 24

    var body: some View {
        ZStack {
            // Card background to match mini post style: layered glass + stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                // Header / Title
                HStack(alignment: .firstTextBaseline) {
                    Text(poll.title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                selectedItemForOptions = GenericItem.poll(poll)
                                showOptionsSheet = true
                        }
                }

                // Context
                if !poll.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    InlineExpandableText(
                        text: poll.context,
                        limit: 60,
                        font: .subheadline
                    )
                    .foregroundStyle(.secondary)
                }

                // Options list styled like mini cells
                VStack(spacing: 10) {
                    ForEach(options.sorted(by: { $0.index < $1.index })) { option in

                        let votePercent: CGFloat =
                        totalVotes == 0
                            ? 0
                            : CGFloat(optionsVotes[option.index]) / CGFloat(totalVotes)

                        Button {
                            let previousChoice = optionChose
                            let newChoice = option.id

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
                                            if let index = options.firstIndex(where: { $0.id == previousChoice }) {
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
                        } label: {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // Track background
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.primary.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(optionChose == option.id ? Color.theme.lightBlue.opacity(0.15) : Color.white.opacity(0.18), lineWidth: 1)
                                        )

                                    // Progress fill when there is a selection
                                    if optionChose != "" {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.theme.lightBlue.opacity(0.15))
                                            .frame(width: min(max(geo.size.width * votePercent, 0), geo.size.width))
                                            .animation(.easeInOut(duration: 0.25), value: optionChose)
                                    }

                                    // Content row
                                    HStack(spacing: 10) {
                                        // Bullet / leading marker
                                        Circle()
                                            .fill(optionChose == option.id ? Color.theme.darkBlue : Color.secondary.opacity(0.4))
                                            .frame(width: 8, height: 8)

                                        Text(option.text)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)

                                        Spacer()

                                        if optionChose != "" {
                                            let percentText = Int(votePercent * 100)
                                            Text("\(percentText)%")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundStyle(optionChose == option.id ? Color.theme.darkBlue : .secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule().fill(Color.primary.opacity(0.06))
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                            .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Footer: linked post + secondary info
                    Divider().opacity(0.5)

                    HStack(spacing: 12) {
                        if poll.linkedPostId != "" {
                            Button {
                                if let index = feedStore.loadedPosts.firstIndex(where: { $0.id == poll.linkedPostId }) {
                                    postLinkFunction(post: feedStore.loadedPosts[index])
                                } else {
                                    Task {
                                        let post = try await homeViewModel.fetchPost(postId: poll.linkedPostId)
                                        postLinkFunction(post: post)
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("View Linked Post")
                                }
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Color.theme.darkBlue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(Color.theme.lightBlue.opacity(0.15))
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "person.3.fill").font(.footnote)
                            Text("Total: \(totalVotes)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.05))
                        )
                    }
            }
            .padding(16)
        }
        .onAppear {
            optionChose = pollsViewModel.getPollChoice(pollId: poll.id)
            for option in options.sorted(by: { $0.index < $1.index }) {
                optionsVotes.append(option.voteCount)
            }
            totalVotes = poll.totalVotes
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(parentPostId: postViewModel.post?.id, selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThickMaterial) // or .regularMaterial
                .background(Color.black.opacity(1)) // makes it darker
        }
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
