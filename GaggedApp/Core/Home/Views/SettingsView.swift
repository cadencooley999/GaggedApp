//
//  SettingsView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/12/25.
//
import Foundation
import SwiftUI

struct SettingsView: View {
    
    @AppStorage("userId") var userId = ""
    
    @EnvironmentObject var vm: SettingsViewModel
    @EnvironmentObject var windowSize: WindowSize
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Binding var selectedTab: TabBarItem
    @Binding var showSettingsView: Bool
    
    @State var showDeleteView: Bool = false
    @State var showCitySelector: Bool = false
    @State var showChangePassword: Bool = false
    @State var showChangeUsername: Bool = false
    @State var showCityNotifPicker: Bool = false

    var body: some View {
        ZStack {
            Background()
                .frame(width: windowSize.size.width, height: windowSize.size.height)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    notificationsSection
                    citySection
                    accountSection
                    legalSection
                    Spacer(minLength: 40)
                }
                .padding(.top, 64)
            }

            // Header overlay with fade like TabHomeView/AddPostView
            VStack {
                ZStack(alignment: .top) {
                    VStack {
                        BackgroundHelper.shared.appleHeaderBlur.frame(height: 92)
                        Spacer()
                    }

                    VStack {
                        header
                            .zIndex(1)
                        Spacer()
                    }
                }
            }

            if showDeleteView {
                deletePopUp(showDeleteView: $showDeleteView)
                    .transition(.opacity)
            }

            if showCitySelector {
                CityPickerView2(dissmissable: true, showCityPickerView: $showCitySelector, selectedTab: $selectedTab)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
            
            if showCityNotifPicker {
                CityPickerView3(showCityPickerView: $showCityNotifPicker)
            }

            if showChangePassword {
                ChangePassword(showChangePassword: $showChangePassword)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }

            if showChangeUsername {
                ChangeUserName(showChangeUsername: $showChangeUsername)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCitySelector)
        .animation(.easeInOut(duration: 0.3), value: showChangePassword)
        .animation(.easeInOut(duration: 0.3), value: showChangeUsername)
        .task {
            vm.getNameAlertStateIfNeeded()
        }
        .onAppear {
            print("Getting noti state")
            vm.getNotiState()
        }
    }
    
    var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettingsView = false
                    }
                }
            Spacer()
            Text("Settings")
                .font(.headline)
            Spacer()
            // Placeholder for symmetry
            Image(systemName: "chevron.left")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .opacity(0)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(height: 55)
    }
    
    
    var citySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Section Title
            Text("Location")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.trashcanGray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // User License Agreement
                settingsButtonRow(
                    icon: "mappin.and.ellipse",
                    iconColor: Color.theme.accent,
                    title: "Change City"
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCitySelector = true
                    }
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // User License Agreement
                settingsButtonRow(
                    icon: "map.circle",
                    iconColor: Color.theme.accent,
                    title: "Location Permissions"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Rectangle().fill(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }
    
    var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Notifications")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.trashcanGray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
//                settingsRow(
//                    icon: "line.3.horizontal",
//                    title: "Open Device Settings",
//                    trailing: {
//                        Image(systemName: "chevron.right")
//                            .font(.title3)
//                            .foregroundStyle(Color.theme.lightBlue)
//                            .onTapGesture {
//                                if let url = URL(string: UIApplication.openSettingsURLString) {
//                                    UIApplication.shared.open(url)
//                                }
//                            }
//                    }
//                )
                
//                Divider()
                
                // --- Enable Notifications ---
                settingsRow(
                    icon: "bell",
                    title: "Enable Notifications",
                    trailing: {
                        CustomToggle(isOn: $vm.notificationToggle)
                            .onTapGesture {
                                vm.setNotifications()
                            }
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // --- Name Mentions Toggle ---
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.text.rectangle")
                                .foregroundColor(Color.theme.accent)
                            Text("When Name Posted")
                                .foregroundColor(Color.theme.accent)
                        }

                        Spacer()

                        CustomToggle(isOn: $vm.nameMentionNotifications)
                            .onTapGesture {
                                if (vm.nameMentionCity != nil && vm.nameToWatchFor != "") {
                                    vm.nameMentionTapped()
                                }
                            }
                            .opacity((vm.nameMentionCity != nil && vm.nameToWatchFor != "") ? 1 : 0.3)
                    }
                    .padding()
                    
                    HStack(spacing: 10) {
                        // City selector chip on the left
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCityNotifPicker = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(vm.nameMentionCity == nil ? "Choose City" : vm.nameMentionCity?.city ?? "")
                                    .foregroundColor(Color.theme.accent)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.accent)
                                    .opacity(0.8)
                            }
                            .frame(height: 40)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.theme.lightGray.opacity(0.20))
                            )
                        }
                        .buttonStyle(.plain)

                        // Name text field on the right
                        TextField("Enter name…", text: $vm.nameToWatchFor)
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(Color.theme.lightGray.opacity(0.20))
                            .cornerRadius(8)
                            .onChange(of: vm.nameToWatchFor) {
                                vm.nameToWatchFor = vm.nameToWatchFor.replacingOccurrences(of: " ", with: "")
                                    .replacingOccurrences(of: "\t", with: "")
                                    .replacingOccurrences(of: "\n", with: "")
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal)
                }
                .opacity(vm.notificationToggle ? 1 : 0.4)
                .padding(.bottom, 12)
            }
            .background(Rectangle().fill(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }
    
    var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Account")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.trashcanGray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // Change Username
                settingsButtonRow(
                    icon: "tag.circle",
                    title: "Change Username"
                ) {
                    showChangeUsername = true
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Email & Password
                settingsButtonRow(
                    icon: "person.badge.key",
                    title: "Change Password"
                ) {
                    showChangePassword = true
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Premium
                settingsButtonRow(
                    icon: "star.fill",
                    title: "Get Premium"
                ) {
                    // action
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Log Out
                settingsButtonRow(
                    icon: "arrow.right.square",
                    iconColor: Color.theme.darkRed,
                    textColor: Color.theme.darkRed,
                    title: "Log Out"
                ) {
                    vm.logOut(userId: userId)
                    profileViewModel.clearStates()
                }
                
                Divider()
                    .padding(.leading, 52)
                
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
            .background(Rectangle().fill(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }
    
    var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Section Title
            Text("Legal & Notices")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.trashcanGray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // User License Agreement
                settingsButtonRow(
                    icon: "doc.text",
                    iconColor: Color.theme.accent,
                    title: "User License Agreement"
                ) {
                    // TODO: open ULA view
                }
                
                Divider()
                    .padding(.leading, 52) // aligns divider under text, not icon
                
                // Privacy Policy
                settingsButtonRow(
                    icon: "lock.shield",
                    iconColor: Color.theme.accent,
                    title: "Privacy Policy"
                ) {
                    // TODO: open privacy view
                }
            }
            .background(Rectangle().fill(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func settingsRow(icon: String, title: String, trailing: () -> some View) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.theme.accent)
            
            Text(title)
                .foregroundColor(Color.theme.accent)
            
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
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Binding var showDeleteView: Bool
    @State var passwordText: String = ""
    @State var failed: Bool = false
    
    var body: some View {
        ZStack {
            // Dimmed background with interactive dismissal
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut) { showDeleteView = false }
                }

            // Glass container
            VStack(spacing: 16) {
                // Title + subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text("Delete Account")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color.theme.accent)

                    if failed {
                        Text("Failed to delete... try again")
                            .font(.footnote)
                            .foregroundColor(Color.theme.darkRed)
                            .transition(.opacity)
                    }

                    Text("Enter your password to confirm. This action cannot be undone.")
                        .font(.footnote)
                        .foregroundColor(Color.theme.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Glass input field (secure)
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.theme.accent)
                        .font(.subheadline)

                    SecureField("Password", text: $passwordText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body)
                }
                .padding(14)
                .glassEffect()

                // Buttons row
                HStack(spacing: 12) {
                    // Cancel (glassy)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { showDeleteView = false }
                    }) {
                        Text("Cancel")
                            .font(.body.weight(.medium))
                            .foregroundColor(Color.theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.theme.lightGray.opacity(0.2))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)

                    // Delete (glassy, emphasized)
                    Button(action: {
                        if !passwordText.isEmpty {
                            Task {
                                let success = try await settingsViewModel.deleteAccount(password: passwordText)
                                profileViewModel.clearStates()
                                if !success {
                                    withAnimation { failed = true }
                                } else {
                                    hasOnboarded = false
                                }
                            }
                        }
                    }) {
                        Text("Delete")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Color.theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.theme.darkRed)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    .disabled(passwordText.isEmpty)
                    .opacity(passwordText.isEmpty ? 0.6 : 1)
                }
            }
            .padding(20)
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal, 24)
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
                .fill(Color.theme.background)
                .frame(width: 20, height: 20)
                .offset(x: isOn ? 10 : -10)
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
    }
}

