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
            Color.white.ignoresSafeArea()
//                .onTapGesture {
//                    UIApplication.shared.endEditing()
//                }
            
            VStack(spacing: 0) {
                VStack {
                    header
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
                                        .tint(Color.theme.white)
                                } else {
                                    Text(canChangeUsername ? "Confirm Username Change" : "Next change available in \(nextChangeText ?? "")")
                                        .font(.headline)
                                        .foregroundStyle(Color.theme.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.tint(Color.theme.darkBlue), in: .rect(cornerRadius: 22))
                        }
                        .disabled(newUsername.isEmpty || isSubmitting || newUsername == currentUsername || !canChangeUsername)
                        .opacity(newUsername.isEmpty || !canChangeUsername || newUsername == currentUsername ? 0.5 : 1)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { _ in
                        UIApplication.shared.endEditing()
                    }
            )
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
        .background(Color.white)
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

