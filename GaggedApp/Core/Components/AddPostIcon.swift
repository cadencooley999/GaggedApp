//
//  AddPostIcon.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import SwiftUI

struct AddPostIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.theme.darkBlue)
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.white)
                .padding()
        }
    }
}

#Preview {
    AddPostIcon()
}
