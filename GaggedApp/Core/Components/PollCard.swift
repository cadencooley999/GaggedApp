//
//  PollCard.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/18/25.
//

import SwiftUI
import Foundation

enum ScreenType {
    case searchFeed
    case pollsFeed
    case profileFeed
    case savedFeed
    case inspectionFeed
}

struct PollCard: View {
    
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var inspectionViewModel: InspectionViewModel
    
    let screenType: ScreenType
    let poll: PollModel
    let options: [PollOption]
    @State var optionChose: String = ""
    @State var optionsVotes: [String:Int] = [:]
    @State var totalVotes: Int = 0
    @State var linkedPostDeleted: Bool = false
    
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var showPollView: Bool
    @Binding var showReportView: Bool
    @Binding var preReportInfo: preReportModel?
    
    @State var showOptionsSheet: Bool = false
    @State var selectedItemForOptions: GenericItem? = nil
    @State var isUpdating: Bool = false
    
    private let cornerRadius: CGFloat = 24

    var body: some View {
        ZStack {
            // Card background to match mini post style: layered glass + stroke
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(colors: [Color.theme.background.opacity(0.08), Color.theme.background.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.theme.background.opacity(0.18), lineWidth: 1)
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
                                preReportInfo = preReportModel(contentType: .poll, contentId: poll.id, contentAuthorId: poll.authorId, reportAuthorId: profileViewModel.userId)
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
                    ForEach(options.sorted(by: { $0.index < $1.index }), id: \.id) { option in

                        Button {
                            let previousChoice = optionChose
                            let newChoice = option.id

                            Task {
                                do {
                                    if previousChoice == "" {
                                        if !isUpdating {
                                            isUpdating = true
                                            try await pollsViewModel.sendVote(
                                                pollId: poll.id,
                                                optionId: newChoice
                                            )
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                optionChose = newChoice
                                            }
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                totalVotes += 1
                                                optionsVotes[newChoice, default: 0] += 1
                                            }
                                            refreshPoll(pollId: poll.id, optionToAdd: option.id, optionToSubtract: "")
                                        }
                                    } else if previousChoice == newChoice {
                                        if !isUpdating {
                                            isUpdating = true
                                            try await pollsViewModel.removeVote(
                                                pollId: poll.id,
                                                optionId: newChoice
                                            )
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                optionChose = ""
                                            }
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                totalVotes -= 1
                                                optionsVotes[newChoice, default: 0] = max(0, optionsVotes[newChoice, default: 0] - 1)
                                            }
                                            refreshPoll(pollId: poll.id, optionToAdd: "", optionToSubtract: option.id)
                                        }
                                    } else {
                                        if !isUpdating {
                                            isUpdating = true
                                            try await pollsViewModel.switchVote(
                                                pollId: poll.id,
                                                oldOptionId: previousChoice,
                                                newOptionId: newChoice
                                            )
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                if let index = options.firstIndex(where: { $0.id == previousChoice }) {
                                                    optionChose = newChoice
                                                }
                                            }
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                optionsVotes[previousChoice, default: 0] = max(0, optionsVotes[previousChoice, default: 0] - 1)
                                                optionsVotes[newChoice, default: 0] += 1
                                            }
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                if let prev = options.first(where: { $0.id == previousChoice }) {
                                                    optionChose = newChoice
                                                    refreshPoll(pollId: poll.id, optionToAdd: option.id, optionToSubtract: prev.id)
                                                }
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
                                let rawCount: Int = optionsVotes[option.id] ?? option.voteCount
                                let total: Int = totalVotes
                                let fraction: CGFloat = total == 0 ? 0 : CGFloat(rawCount) / CGFloat(total)
                                let width: CGFloat = min(max(geo.size.width * fraction, 0), geo.size.width)
                                ZStack(alignment: .leading) {
                                    // Track background
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.primary.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(optionChose == option.id ? Color.theme.lightBlue.opacity(0.15) : Color.theme.background.opacity(0.18), lineWidth: 1)
                                        )

                                    // Progress fill when there is a selection
                                    if optionChose != "" {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.theme.lightBlue.opacity(0.15))
                                            .frame(width: width)
                                            .animation(.easeInOut(duration: 0.25), value: fraction)
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
                                            let percentString: String = total == 0
                                                ? "0%"
                                                : (Double(rawCount) / Double(total)).formatted(.percent.precision(.fractionLength(0)))
                                            Text(percentString)
                                                .font(.footnote.weight(.semibold))
                                                .contentTransition(.numericText())
                                                .animation(.easeInOut(duration: 0.25), value: fraction)
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
                .allowsHitTesting(screenType == .inspectionFeed ? false : true)

                // Footer: linked post + secondary info
                    Divider().opacity(0.5)

                    HStack(spacing: 12) {
                        if poll.linkedPostId != "" {
                            Button {
                                if let index = feedStore.loadedPosts.firstIndex(where: { $0.id == poll.linkedPostId }) {
                                    postLinkFunction(post: feedStore.loadedPosts[index])
                                } else {
                                    Task {
                                        do {
                                            let post = try await homeViewModel.fetchPost(postId: poll.linkedPostId)
                                            postLinkFunction(post: post)
                                        }
                                        catch {
                                            linkedPostDeleted = true
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    if !linkedPostDeleted {
                                        Image(systemName: "arrow.up.right.square")
                                        Text("View Linked Post")
                                    } else {
                                        Image(systemName: "arrow.up.right.square")
                                        Text("Post Unavailable")
                                    }
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
                            Text("Total: \(poll.totalVotes)")
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
        .onChange(of: options.map(\.voteCount)) {
            optionChose = pollsViewModel.getPollChoice(pollId: poll.id)
            
            // Set UI States for animation
            optionsVotes = [:]
            for opt in options {
                optionsVotes[opt.id] = opt.voteCount
            }
            totalVotes = poll.totalVotes
            isUpdating = false
        }
        .onAppear {
            optionChose = pollsViewModel.getPollChoice(pollId: poll.id)
            optionsVotes = [:]
            for opt in options {
                optionsVotes[opt.id] = opt.voteCount
            }
            totalVotes = poll.totalVotes
            isUpdating = false
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(parentPostId: postViewModel.post?.id, selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView, showPollView: $showPollView, showReportSheet: $showReportView, preReportInfo: $preReportInfo, screenType: screenType)
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
            try await postViewModel.loadInitialRootComments()
            postViewModel.commentsIsLoading = false
        }
    }

    func refreshPoll(pollId: String, optionToAdd: String, optionToSubtract: String) {
//        switch screenType {
//        case .searchFeed:
//            searchViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
//        case .pollsFeed:
//            pollsViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
//        case .profileFeed:
//            profileViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
//        case .savedFeed:
//            profileViewModel.refreshSavedFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
//        }
//
        searchViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        pollsViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        profileViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        profileViewModel.refreshSavedFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        inspectionViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)

    }
    
}
