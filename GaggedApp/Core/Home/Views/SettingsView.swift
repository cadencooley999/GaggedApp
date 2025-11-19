//
//  SettingsView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/12/25.
//
import Foundation
import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    
    @Binding var showSettingsView: Bool
    @Binding var hideTabBar: Bool
    
    @State var showDeleteView: Bool = false

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.bottom)
                    Divider()
                    notificationsSection
                        .padding(.top)
                    accountSection
                        .padding(.top)
                    legalSection
                        .padding(.top)
                    Spacer(minLength: 40)
                }
            }
            
            if showDeleteView {
                deletePopUp(showDeleteView: $showDeleteView)
                    .transition(.opacity)
            }
        }
    }
    
    var header: some View {
        VStack {
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
                Spacer()
                Text("Settings")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(.trailing, 8)
                    .opacity(0)
            }
        }
    }
    
    
    var citySection: some View {
        VStack {
            Text("Current City: New York")
            Text("Change City")
        }
    }
    
    var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Notifications")
                .font(.headline)
                .foregroundColor(Color.theme.gray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // --- Enable Notifications ---
                settingsRow(
                    icon: "bell",
                    title: "Enable Notifications",
                    trailing: {
                        CustomToggle(isOn: $vm.notificationsEnabled)
                    }
                )
                
                Divider()
                
                // --- Name Mentions Toggle ---
                VStack(spacing: 6) {
                    settingsRow(
                        icon: "person.text.rectangle",
                        title: "When Name Mentioned",
                        trailing: {
                            CustomToggle(isOn: $vm.nameMentionNotifications)
                        }
                    )
                    
                    // Textfield always visible
                    TextField("Enter name…", text: $vm.nameToWatchFor)
                        .padding(10)
                        .background(Color.theme.lightGray.opacity(0.20))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .opacity(vm.nameMentionNotifications ? 1 : 0.4)
                        .disabled(!vm.nameMentionNotifications)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.bottom, 12)
            }
            .background(Color.theme.lightGray.opacity(0.15))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Account")
                .font(.headline)
                .foregroundColor(Color.theme.gray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // Change Username
                settingsButtonRow(
                    icon: "person.badge.key",
                    title: "Change Username"
                ) {
                    // action
                }
                
                Divider()
                
                // Email & Password
                settingsButtonRow(
                    icon: "envelope.badge",
                    title: "Email & Password"
                ) {
                    // action
                }
                
                Divider()
                
                // Premium
                settingsButtonRow(
                    icon: "star.fill",
                    title: "Get Premium"
                ) {
                    // action
                }
                
                Divider()
                
                // Log Out
                settingsButtonRow(
                    icon: "arrow.right.square",
                    iconColor: Color.theme.darkRed,
                    textColor: Color.theme.darkRed,
                    title: "Log Out"
                ) {
                    vm.logOut()
                }
                
                Divider()
                
                // Delete Account
                settingsButtonRow(
                    icon: "trash",
                    iconColor: Color.theme.darkRed,
                    textColor: Color.theme.darkRed,
                    title: "Delete Account"
                ) {
                    withAnimation {
                        showDeleteView = true
                    }
                }
            }
            .background(Color.theme.lightGray.opacity(0.15))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Section Title
            Text("Legal & Notices")
                .font(.headline)
                .foregroundColor(Color.theme.gray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // User License Agreement
                settingsButtonRow(
                    icon: "doc.text",
                    iconColor: .black,
                    title: "User License Agreement"
                ) {
                    // TODO: open ULA view
                }
                
                Divider()
                    .padding(.leading, 52) // aligns divider under text, not icon
                
                // Privacy Policy
                settingsButtonRow(
                    icon: "lock.shield",
                    iconColor: .black,
                    title: "Privacy Policy"
                ) {
                    // TODO: open privacy view
                }
            }
            .background(Color.theme.lightGray.opacity(0.15))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func settingsRow(icon: String, title: String, trailing: () -> some View) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
            
            Text(title)
                .foregroundColor(.black)
            
            Spacer()
            
            trailing()
        }
        .padding()
    }

    @ViewBuilder
    func settingsButtonRow(
        icon: String,
        iconColor: Color = Color.theme.accent,
        textColor: Color = Color.theme.accent,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .foregroundColor(textColor)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}



struct deletePopUp: View {
    
    @AppStorage("hasOnboarded") var hasOnboarded = true
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var showDeleteView: Bool
    @State var passwordText: String = ""
    @State var failed: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap outside to dismiss
                    withAnimation(.easeInOut) { showDeleteView = false }
                }
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Are you sure?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.accent)
                    
                    if failed {
                        Text("Failed to delete - try again")
                            .font(.caption)
                            .foregroundColor(Color.theme.darkRed)
                            .padding(.vertical, 4)
                    }
                    
                    Text("Enter password to delete account")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    TextField("Password...", text: $passwordText)
                        .autocapitalization(.none)
                        .padding(10)
                        .background(Color.theme.lightGray.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding()
                
                Divider()
                
                // Buttons
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeleteView = false
                        }
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(Color.theme.accent)
                    }
                    
                    Divider()
                        .frame(height: 44)
                        .background(Color.theme.lightGray)
                    
                    Button(action: {
                        if passwordText != "" {
                            Task {
                                let success = try await settingsViewModel.deleteAccount(password: passwordText)
                                if !success {
                                   failed = true
                                }
                                else {
                                    hasOnboarded = false
                                }
                            }
                        }
                    }) {
                        Text("Delete Account")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(Color.theme.darkRed)
                            .fontWeight(.semibold)
                    }
                }
                .frame(height: 44)
            }
            .background(Color.theme.background)
            .cornerRadius(16)
            .padding(.horizontal, 32)
            .shadow(radius: 10)
        }
    }
}

struct CustomToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isOn ? Color.theme.darkBlue : Color.gray.opacity(0.3))
                .frame(width: 44, height: 24)
            
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .offset(x: isOn ? 10 : -10)
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
        .onTapGesture {
            isOn.toggle()
        }
    }
}
