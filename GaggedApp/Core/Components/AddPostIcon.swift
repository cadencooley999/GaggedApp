//
//  AddPostIcon.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/5/25.
//

import SwiftUI

struct AddPostIcon: View {
    var body: some View {
        // We use the Image itself to build the component,
        // mirroring the clean, bordered style of the header's search button.
        Image(systemName: "plus")
        // 1. Make it Bigger: Use a larger font for the icon
            .font(.title)
            .foregroundColor(Color.theme.white)
        // 2. Add padding to increase the overall size and tap target
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16) // Slightly larger corner radius for a larger button
                // 3. Fit the Header Style: Use a stroke instead of a solid fill
                    .fill(Color.theme.darkBlue)
            )
        // Note: Shadow is usually handled by the TabBar, but we can keep a subtle one if desired.
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1)
    }
}

#Preview {
    AddPostIcon()
}
