//
//  OnboardingChip.swift
//  GaggedApp
//
//  Created by Caden Cooley on 6/24/26.
//
import SwiftUI

enum ChipStyle { case blue, gold }

struct Chip: View {
    let label: String
    let style: ChipStyle
    
    var textColor: Color {
        style == .blue ? Color(Color.theme.darkBlue) : Color(Color.theme.orange)
    }
    var bgColor: Color {
        style == .blue
        ? Color(Color.theme.lightBlue).opacity(0.15)
        : Color(Color.theme.orange).opacity(0.15)
    }
    
    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 13)
            .padding(.vertical, 5)
            .background(bgColor)
            .clipShape(Capsule())
    }
}
