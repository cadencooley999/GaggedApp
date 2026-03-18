//
//  MiniPollView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/25/26.
//

import SwiftUI

struct MiniPollView: View {
    let poll: PollWithOptions

    private let cornerRadius: CGFloat = 24
    
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    @Binding var showPollView: Bool
    @Binding var showReportView: Bool
    @Binding var preReportInfo: preReportModel?
    
    let screenType: ScreenType
    
    @Namespace var pollSpace

    var body: some View {
        ZStack{
            if poll.options.count < 1 {
                ZStack {
                    // Background glass card
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    HStack(spacing: 12) {
                        
                        Text(poll.poll.title)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer(minLength: 8)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.3.fill")
                                .font(.footnote)
                            Text("Total: \(poll.poll.totalVotes)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.05))
                        )
                    }
                    .padding(14)
                    
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
                .transition(.opacity)
            }
            else {
                PollCard(screenType: screenType, poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView, showPollView: $showPollView, showReportView: $showReportView, preReportInfo: $preReportInfo)
                    .transition(.opacity)
            }
        }
        .onChange(of: poll.options.map(\.voteCount)) {
            print("votes changed")
        }
    }
}
