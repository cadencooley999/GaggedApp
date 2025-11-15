//
//  InlineExpandableText.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/11/25.
//


import SwiftUI

struct InlineExpandableText: View {
    let text: String
    let limit: Int
    @State private var expanded = false
    
    var body: some View {
        Group {
            if text.count <= limit {
                Text(text)
                    .font(.body)
            }
            else if text.count > limit && !expanded {
                // Truncated text + inline "See more"
                (
                    Text(String(text.prefix(limit))) +
                    Text("... ") +
                    Text("see more")
                        .foregroundColor(Color.theme.gray)
                )
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        expanded = true
                    }
                }
            } else {
                // Full text + inline "See less"
                (
                    Text(text) +
                    Text("  see less")
                        .foregroundColor(Color.theme.gray)
                )
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        expanded = false
                    }
                }
            }
        }
        .font(.body)
        .lineLimit(nil)
    }
}
