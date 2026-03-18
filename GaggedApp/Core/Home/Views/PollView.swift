//
//  PollView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/1/26.
//
import SwiftUI
import Foundation

struct PollView: View {
    
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var feedStore: FeedStore
    
    @Binding var showPollView: Bool
    @Binding var showPostView: Bool
    @Binding var selectedPoll: PollWithOptions?
    @Binding var showReportView: Bool
    @Binding var preReportInfo: preReportModel?
    @Binding var selectedPost: PostModel?
    
    @State var selectedItemForOptions: GenericItem? = nil
    @State var showOptionsSheet: Bool = false
    
    @State private var optionChose: String = ""
    @State private var optionsVotes: [Int] = []
    @State private var totalVotes: Int = 0
    
    @State var linkedPostDeleted: Bool = false  
    
    var body: some View {
        ZStack {
            Background()
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                header
                    .frame(height: 55)
                pollinfo
                
            }
        }
        .sheet(isPresented: $showOptionsSheet) {
            OptionsSheet(selectedItemForOptions: $selectedItemForOptions, showOptionsSheet: $showOptionsSheet, showPostView: $showPostView, showPollView: $showPollView, showReportSheet: $showReportView, preReportInfo: $preReportInfo, screenType: .pollsFeed)
                .presentationDetents([.medium])
        }
        .task(id: pollsViewModel.poll?.id) {
            // Reset and initialize state when poll changes
            optionChose = ""
            optionsVotes = []
            totalVotes = 0
            if let pollWithOptions = pollsViewModel.poll {
                optionChose = pollsViewModel.getPollChoice(pollId: pollWithOptions.id)
                for opt in pollWithOptions.options.sorted(by: { $0.index < $1.index }) {
                    optionsVotes.append(opt.voteCount)
                }
                totalVotes = pollWithOptions.poll.totalVotes
                print(optionsVotes)
            }
        }
    }
    
    var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        UIApplication.shared.endEditing()
                        showPollView = false
                        selectedPoll = nil
                        pollsViewModel.poll = nil
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack {
                Text("Poll")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.theme.accent)
                HStack(spacing: 4) {
                    if let poll = pollsViewModel.poll {
                        Text("by \(poll.poll.authorName)")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundStyle(Color.theme.gray)
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .center)
            GlassEffectContainer {
                HStack {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .glassEffect(.regular.interactive())
                        .onTapGesture {
                            if let poll = pollsViewModel.poll {
                                selectedItemForOptions = GenericItem.poll(poll.poll)
                                showOptionsSheet = true
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    var pollinfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let pollWithOptions = pollsViewModel.poll {
                // Title
                Text(pollWithOptions.poll.title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.theme.accent)
                    .fixedSize(horizontal: false, vertical: true)

                // Context (optional)
                if !pollWithOptions.poll.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    InlineExpandableText(
                        text: pollWithOptions.poll.context,
                        limit: 120,
                        font: .body
                    )
                    .foregroundStyle(.secondary)
                }

                // Options list (styled like PollCard)
                if !pollWithOptions.options.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(pollWithOptions.options.sorted(by: { $0.index < $1.index })) { option in
                            Button {
                                let previousChoice = optionChose
                                let newChoice = option.id

                                Task {
                                    do {
                                        if previousChoice == "" {
                                            try await pollsViewModel.sendVote(
                                                pollId: pollWithOptions.id,
                                                optionId: newChoice
                                            )
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                optionChose = newChoice
                                                optionsVotes[option.index] += 1
                                                totalVotes += 1
                                            }
                                            refreshPoll(pollId: pollWithOptions.id, optionToAdd: option.id, optionToSubtract: "")
                                        } else if previousChoice == newChoice {
                                            try await pollsViewModel.removeVote(
                                                pollId: pollWithOptions.id,
                                                optionId: newChoice
                                            )
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                optionChose = ""
                                                optionsVotes[option.index] -= 1
                                                totalVotes -= 1
                                            }
                                            refreshPoll(pollId: pollWithOptions.id, optionToAdd: "", optionToSubtract: option.id)
                                        } else {
                                            try await pollsViewModel.switchVote(
                                                pollId: pollWithOptions.id,
                                                oldOptionId: previousChoice,
                                                newOptionId: newChoice
                                            )
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                if let prev = pollWithOptions.options.first(where: { $0.id == previousChoice }) {
                                                    optionChose = newChoice
                                                    optionsVotes[option.index] += 1
                                                    optionsVotes[prev.index] -= 1
                                                    refreshPoll(pollId: pollWithOptions.id, optionToAdd: option.id, optionToSubtract: prev.id)
                                                }
                                            }
                                        }
                                    } catch {
                                        // rollback on failure
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
                                                    .stroke(optionChose == option.id ? Color.theme.lightBlue.opacity(0.15) : Color.theme.background.opacity(0.18), lineWidth: 1)
                                            )

                                        // Progress fill when there is a selection
                                        if optionChose != "" {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.theme.lightBlue.opacity(0.15))
                                                .frame(width: min(max(geo.size.width * (totalVotes == 0 ? 0 : CGFloat(optionsVotes[option.index]) / CGFloat(totalVotes)), 0), geo.size.width))
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
                                                Text(
                                                    totalVotes == 0
                                                        ? "0%"
                                                        : (Double(optionsVotes[option.index]) / Double(totalVotes))
                                                            .formatted(.percent.precision(.fractionLength(0)))
                                                )
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
                                .frame(height: 48)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Linked post (optional) - larger capsule style inspired by PollCard
                if pollWithOptions.poll.linkedPostId != "" && !pollWithOptions.poll.linkedPostName.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linked Post")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.right.square")
                            Text(linkedPostDeleted ? "Post Unavailable" : pollWithOptions.poll.linkedPostName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer(minLength: 0)
                        }
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.theme.darkBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(Color.theme.lightBlue.opacity(0.18))
                        )
                    }
                    .onTapGesture {
                        if let index = feedStore.loadedPosts.firstIndex(where: { $0.id == pollWithOptions.poll.linkedPostId }) {
                            postLinkFunction(post: feedStore.loadedPosts[index])
                        } else {
                            Task {
                                do {
                                    let post = try await homeViewModel.fetchPost(postId: pollWithOptions.poll.linkedPostId)
                                    postLinkFunction(post: post)
                                }
                                catch {
                                    linkedPostDeleted = true
                                }
                            }
                        }
                    }
                    .padding(.top, 6)
                }
            } else {
                // Placeholder / skeleton when no poll is loaded
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.theme.gray.opacity(0.2)).frame(height: 18)
                    RoundedRectangle(cornerRadius: 6).fill(Color.theme.gray.opacity(0.15)).frame(height: 14)
                    RoundedRectangle(cornerRadius: 6).fill(Color.theme.gray.opacity(0.1)).frame(height: 14)
                }
                .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
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
        searchViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        pollsViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        profileViewModel.refreshFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
        profileViewModel.refreshSavedFeedPoll(pollId: pollId, optionToAdd: optionToAdd, optionToSubtract: optionToSubtract)
    }
}
