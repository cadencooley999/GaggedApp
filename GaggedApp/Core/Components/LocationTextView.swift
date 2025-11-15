//
//  LocationTextView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/25/25.
//


import SwiftUI

struct LocationTextView: View {
    let text: String
    
    var body: some View {
        if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
                .font(.body)
                .tint(Color.theme.darkBlue) // link color
        } else {
            Text(text)
                .font(.body)
        }
    }
}
