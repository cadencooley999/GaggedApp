//
//  EllipsesToggleView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/23/25.
//

import SwiftUI

public struct EllipsesToggleView: View {
    
    @Binding var toggleValue: Bool
    let accentColor: Color
    
    public var body: some View {
        HStack(spacing: 0){
            Circle()
                .frame(width: 6)
                .foregroundColor(toggleValue ? Color.theme.gray : accentColor)
                .padding(.trailing, 4)
            Circle()
                .frame(width: 6)
                .foregroundColor(toggleValue ? accentColor : Color.theme.lightGray)
        }
    }
}
