//
//  AddPostIcon.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import SwiftUI

struct AddPostIcon: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.title)
            .foregroundColor(Color.theme.white)
            .padding(12)
            .background(
                Circle()
                    .fill(Color.theme.darkBlue)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1)
    }
}

#Preview {
    AddPostIcon()
}
