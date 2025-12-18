//
//  ProfilePic.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/5/25.
//
import Foundation
import SwiftUI

struct ProfilePic: View {
    let address: String          // image asset name
    let size: CGFloat // width & height
    
    var body: some View {
        if address != "" {
            Image(address)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(radius: 2)
        }
        else {
            Image("ProfPic1")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(radius: 2)
        }
    }
}
