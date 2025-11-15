//
//  SettingsView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/12/25.
//
import Foundation
import SwiftUI

struct SettingsView: View {
    
    @Binding var showSettingsView: Bool
    @Binding var hideTabBar: Bool

    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            VStack {
                header
                    .padding()
                Divider()
                
                Spacer()
            }
        }
    }
    
    var header: some View {
        VStack{
            HStack(spacing: 0){
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(.trailing, 8)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettingsView = false
                            hideTabBar = false
                        }
                    }
                Text("Settings and OTHER STUFF")
                    .font(.title2)
                Spacer()
            }
        }
    }
    
    var notificationsSection: some View {
        VStack {
            Text("Notifications: ON")
            Text("Turn Off Notifications")
        }
    }
    
    var appearanceSection: some View {
        VStack {
            Text("Dark Mode: ON")
            Text("Turn Off Dark Mode")
        }
    }
    
    var citySection: some View {
        VStack {
            Text("Current City: New York")
            Text("Change City")
        }
    }
    
    var acccountSection: some View {
        VStack {
            Text("Log Out")
            Text("Delete Account")
        }
    }
}
