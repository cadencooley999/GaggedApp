//
//  ChangeUserName.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/8/25.
//

import SwiftUI

struct ChangeUserName: View {
    
    @State var canChangeUsername: Bool = true
    
    // MARK: - State
    @State private var newUsername: String = ""
    @State var nextChangeText: String? = nil
    @State private var showConfirmAlert = false
    @State private var isSubmitting = false
    @State var usernameDirty = false
    
    // Replace this with your real source
    @AppStorage("username") private var currentUsername: String = ""
    
    @Binding var showChangeUsername: Bool
    
    let userManager = UserManager.shared
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
//                .onTapGesture {
//                    UIApplication.shared.endEditing()
//                }
            
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Current Username (Large)
                        Text("@\(currentUsername)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.theme.darkBlue)
                        
                        // Blurb
                        Text("Choose wisely, you can only change your username once every six months.")
                            .font(.caption)
                            .foregroundStyle(Color.theme.gray)
                        
                        // New Username Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Username")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "tag")
                                    .foregroundStyle(Color.theme.darkBlue)
                                TextField("Enter new username", text: $newUsername)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChange(of: newUsername, {
                                        newUsername = newUsername.replacingOccurrences(of: " ", with: "")
                                            .replacingOccurrences(of: "\t", with: "")
                                            .replacingOccurrences(of: "\n", with: "")
                                        newUsername = String(newUsername.prefix(16))
                                    })
                            }
                            .padding(14)
                            .glassEffect(.regular, in: .rect(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
                            
                            if usernameDirty {
                                Text("This username is not appropriate. Be good!")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.darkRed)
                                    .padding(.leading, 8)
                            }
                        }
                        
                        // Submit Button
                        Button {
                            showConfirmAlert = true
                        } label: {
                            ZStack {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(Color.theme.background)
                                } else {
                                    Text(canChangeUsername ? "Confirm Username Change" : "Next change available in \(nextChangeText ?? "")")
                                        .font(.headline)
                                        .foregroundStyle(Color.theme.background)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .glassEffect(.regular.tint(Color.theme.darkBlue), in: .rect(cornerRadius: 22))
                        }
                        .disabled(newUsername.isEmpty || isSubmitting || newUsername == currentUsername || !canChangeUsername)
                        .opacity(newUsername.isEmpty || !canChangeUsername || newUsername == currentUsername ? 0.5 : 1)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                    .padding(.top, 72)
                    .padding(.bottom, 100)
                }
                .onScrollPhaseChange({ oldPhase, newPhase in
                    if newPhase == .interacting {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            UIApplication.shared.endEditing()
                        }
                    }
                })
            }
            
            // Header overlay with blur, pinned to top
            VStack {
                ZStack(alignment: .top) {
                    VStack {
                        BackgroundHelper.shared.appleHeaderBlur.frame(height: 92)
                        Spacer()
                    }
                    VStack {
                        header
                            .frame(height: 55)
                            .zIndex(1)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            Task {
                if let lastChange = try await userManager.lastChange() {
                    canChangeUsername = canChangeUsername(last: lastChange)
                    if !canChangeUsername {
                        nextChangeText = timeUntilSixMonths(from: lastChange)
                    }
                }
                else {
                    canChangeUsername = true
                }
            }
        }
        .alert("Are you sure?", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Change Username", role: .destructive) {
                Task {
                    try await submitUsernameChange()
                }
            }
        } message: {
            Text("Your username can only be changed once every six months. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                        showChangeUsername = false
                    }

                Spacer()

                Text("Change Username")
                    .font(.headline)

                Spacer()

                // Placeholder for symmetry
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .opacity(0)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(height: 55)
    }
    
    // MARK: - Submit Logic
    private func submitUsernameChange() async throws {
        usernameDirty = false
        guard !newUsername.isEmpty else { return }
        guard ProfanityFilter.isUsernameClean(newUsername) else {
            usernameDirty = true
            return
        }
        
        if canChangeUsername {
            isSubmitting = true
            try await userManager.changeUsername(newUsername: newUsername)
            currentUsername = newUsername
            isSubmitting = false
            showChangeUsername = false
        }
    }
    
    func timeUntilSixMonths(from pastDate: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Target date = 6 months after the given date
        guard let targetDate = calendar.date(byAdding: .month, value: 6, to: pastDate) else {
            return "0d"
        }
        
        // If already passed
        if now >= targetDate {
            return "0d"
        }
        
        let components = calendar.dateComponents([.month, .day], from: now, to: targetDate)
        
        let months = components.month ?? 0
        let days = components.day ?? 0
        
        if months > 0 {
            return "\(months)mo"
        } else {
            return "\(days)d"
        }
    }
    
    func canChangeUsername(last: Date) -> Bool {
        guard let sixMonthsLater = Calendar.current.date(byAdding: .month, value: 6, to: last) else {
            // If date math fails, be safe and block
            return false
        }
        
        let now = Date()
        
        return now >= sixMonthsLater
    }
}

