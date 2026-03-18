//
//  TagSheet.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/31/25.
//

import Foundation
import SwiftUI

struct TagSheet: View {
    
    @EnvironmentObject var addVm: AddPostViewModel
    @Binding var showTagSheet: Bool
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    header
                    tagSection
                }
            }
        }
    }
    
    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add tags")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(addVm.selectedTags.count)/3 selected")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Done")
                .font(.subheadline.bold())
                .foregroundStyle(Color.theme.darkBlue)
                .padding(12)
                .glassEffect(.regular.tint(Color.theme.lightBlue.opacity(0.2)), in: .rect(cornerRadius: 25))
                .onTapGesture {
                    showTagSheet = false
                }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    var tagSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(TagManager.shared.categories.sorted(by: { $0.order < $1.order }), id: \.id) { category in
                VStack(alignment: .leading, spacing: 12) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    FlowLayout(spacing: 8) {
                        ForEach(TagManager.shared.tagList.filter({ $0.category == category.title }), id: \.title) { tag in
                            let isSelected = addVm.selectedTags.contains(where: { $0.title == tag.title })
                            TagPill(title: tag.title, isSelected: isSelected, color: Color.theme.darkBlue)
                                .contentShape(Capsule())
                                .onTapGesture {
                                    if isSelected {
                                        addVm.selectedTags.removeAll(where: { $0.title == tag.title })
                                    } else if addVm.selectedTags.count < 3 {
                                        addVm.selectedTags.append(tag)
                                    }
                                }
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
//                    Color.theme.background.cornerRadius(16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.theme.darkBlue.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
        
    
}

struct TagPill: View {
    
    let title: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        Text(displayTitle)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .fixedSize(horizontal: true, vertical: false)
            .background(background)
            .overlay(overlay)
            .foregroundStyle(isSelected ? Color.theme.background : Color.theme.accent)
            .clipShape(Capsule())
            .animation(.snappy(duration: 0.2), value: isSelected)
    }
    
    private var displayTitle: String {
        title.hasPrefix("#") ? title : "#\(title)"
    }

    private var background: some View {
        Group {
            if isSelected {
                LinearGradient(colors: [color, color.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                color.opacity(0.08)
            }
        }
    }

    private var overlay: some View {
        Group {
            if isSelected {
                Capsule().stroke(color.opacity(0.3), lineWidth: 1)
            } else {
                Capsule().stroke(color.opacity(0.35), lineWidth: 1)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    struct Cache {
        var sizes: [CGSize] = []
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache(sizes: Array(repeating: .zero, count: subviews.count))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[Int]] = [[]]
        var currentRowWidth: CGFloat = 0
        var currentRowIndices: [Int] = []

        cache.sizes = subviews.enumerated().map { _, subview in
            subview.sizeThatFits(.unspecified)
        }

        for (index, size) in cache.sizes.enumerated() {
            let itemWidth = size.width
            if currentRowIndices.isEmpty || currentRowWidth + itemWidth + (currentRowIndices.isEmpty ? 0 : spacing) <= maxWidth {
                currentRowIndices.append(index)
                currentRowWidth += (currentRowIndices.count == 1 ? 0 : spacing) + itemWidth
            } else {
                rows.append(currentRowIndices)
                currentRowIndices = [index]
                currentRowWidth = itemWidth
            }
        }
        if !currentRowIndices.isEmpty { rows.append(currentRowIndices) }
        if rows.first?.isEmpty == true { rows.removeFirst() }

        var totalHeight: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { cache.sizes[$0].height }.max() ?? 0
            totalHeight += rowHeight
            if row != rows.last { totalHeight += spacing }
        }

        let width = min(maxWidth, cache.sizes.map { $0.width }.max() ?? 0)
        return CGSize(width: proposal.width ?? width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = cache.sizes[index]
            if x != bounds.minX && x + size.width > bounds.maxX {
                // Move to next row
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
