//
//  MiniPollView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/25/26.
//

import SwiftUI

struct MiniPollView: View {
    let poll: PollWithOptions

    private let cornerRadius: CGFloat = 16
    
    @Binding var selectedPost: PostModel?
    @Binding var showPostView: Bool
    
    @Namespace var pollSpace

    var body: some View {
        if poll.options.count < 1 {
            ZStack {
                // Background glass card
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

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
            PollCard(poll: poll.poll, options: poll.options, selectedPost: $selectedPost, showPostView: $showPostView)
                .transition(.opacity)
        }
    }
}
