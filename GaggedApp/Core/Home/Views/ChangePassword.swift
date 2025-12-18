//
//  Reset Password.swift
//  GaggedApp
//
//  Created by Caden Cooley on 12/7/25.
//

import SwiftUI

struct ChangePassword: View {
    
    func safeArea() -> UIEdgeInsets {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first
        else { return .zero }

        return window.safeAreaInsets
    }
    
    @Binding var showChangePassword: Bool
    @AppStorage("userEmail") var userEmail: String = ""
    
    @State var emailText: String = ""
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var showResetSheet = false
    @State private var isSubmitting = false
    @State var resultText: String = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State var passwordCapLetter: Bool = false
    @State var passwordNumber: Bool = false
    @State var passwordLength: Bool = false
    @State var isNewPasswordValid: Bool = false
    
    let userManager = UserManager.shared
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
               VStack {
                    header
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Subtitle / Requirements
                        Text("Your password must be at least 8 characters long, including a number and capital letter")
                            .font(.caption)
                            .foregroundStyle(Color.theme.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            
                            TextField("Enter account email", text: $emailText)
                                .padding(12)
                                .background(Color.theme.lightGray.opacity(0.15))
                                .cornerRadius(12)
                        }
                        
                        // MARK: - Current Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Password")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            
                            HStack {
                                Group {
                                    if showCurrentPassword {
                                        TextField("Enter current password", text: $currentPassword)
                                    } else {
                                        SecureField("Enter current password", text: $currentPassword)
                                    }
                                }
                                .frame(height: 20) // <-- Add this
                                
                                Button {
                                    showCurrentPassword.toggle()
                                } label: {
                                    Image(systemName: showCurrentPassword ? "eye" : "eye.slash")
                                        .foregroundColor(Color.theme.gray)
                                        .frame(height: 20)
                                }
                            }
                            .padding(12)
                            .background(Color.theme.lightGray.opacity(0.15))
                            .cornerRadius(12)
                        }

                        // MARK: - New Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundStyle(Color.theme.gray)
                            
                            HStack {
                                Group {
                                    if showNewPassword {
                                        TextField("Enter new password", text: $newPassword)
                                    } else {
                                        SecureField("Enter new password", text: $newPassword)
                                    }
                                }
                                .frame(height: 20) // <-- Add this
                                .onChange(of: newPassword) {
                                   isNewPasswordValid = validatePassword(newPassword)
                                }
                                
                                Button {
                                    showNewPassword.toggle()
                                } label: {
                                    Image(systemName: showNewPassword ? "eye" : "eye.slash")
                                        .foregroundColor(Color.theme.gray)
                                        .frame(height: 20)
                                }
                            }
                            .padding(12)
                            .background(Color.theme.lightGray.opacity(0.15))
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4){
                                HStack {
                                    if passwordLength {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.theme.darkBlue)
                                            .font(.footnote)
                                    } else {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.theme.gray)
                                            .font(.footnote)
                                    }
                                    Text("8 characters")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    if passwordNumber {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.theme.darkBlue)
                                            .font(.footnote)
                                    } else {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.theme.gray)
                                            .font(.footnote)
                                    }
                                    Text("Number")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    if passwordCapLetter {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.theme.darkBlue)
                                            .font(.footnote)
                                    } else {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.theme.gray)
                                            .font(.footnote)
                                    }
                                    Text("Capital Letter")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Reset Link
                        Button {
                            showResetSheet = true
                        } label: {
                            Text("Forgot your password?")
                                .font(.caption)
                                .foregroundStyle(Color.theme.darkBlue)
                        }
                        .padding(.top, 4)
                        .padding(.bottom)

                        // Confirm Button
                        
                        if resultText != "" {
                            Text(resultText)
                                .font(.caption)
                                .foregroundStyle(resultText.contains("Failed") ? Color.theme.darkRed : Color.theme.darkBlue)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        Button {
                            Task {
                                await submitPasswordChange()
                            }
                        } label: {
                            if !isSubmitting {
                                Text("Confirm Password Change")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color.theme.darkBlue)
                                    )
                            } else {
                                HStack {
                                    Spacer()
                                    CircularLoadingView()
                                        .frame(width: 20, height: 20)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.theme.darkBlue)
                                )
                            }
                        }
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || isSubmitting || !isNewPasswordValid)
                        .opacity(currentPassword.isEmpty || newPassword.isEmpty || !isNewPasswordValid ? 0.5 : 1)
                        
                    }
                    .padding()
                }
               .gesture(
                   DragGesture()
                       .onEnded { _ in
                           UIApplication.shared.endEditing()
                       }
               )
                Spacer()
            }
        }
        .onAppear {
            emailText = userEmail
        }
        .sheet(isPresented: $showResetSheet) {
            // Placeholder – you'll build this later
            ForgotPasswordSheet(showResetSheet: $showResetSheet, userEmail: userEmail)
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
                            UIApplication.shared.endEditing()
                            showChangePassword = false
                        }
                    }
                Spacer()
                Text("Change Password")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(.trailing, 8)
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
        }
        .frame(height: 55)
    }
    
    
    private func submitPasswordChange() async {
        isSubmitting = true
        defer { isSubmitting = false }
        guard isNewPasswordValid else {return}
        do {
            try await userManager.reauthenticateAndChangePassword(email: emailText, currentPassword: currentPassword, newPassword: newPassword)
            resultText = "Password changed successfully."
            showChangePassword = false
        } catch {
            resultText = "Failed to change password. Check credentials"
            print(error.localizedDescription)
        }
        // Hook Firebase logic here later
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
        }
    }
    
    func validatePassword(_ password: String) -> Bool {
        passwordLength = password.count > 7
        passwordCapLetter = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        passwordNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        if passwordLength && passwordCapLetter && passwordNumber {
            return true
        }
        
        return false
    }
}

struct ForgotPasswordSheet: View {
    
    @Binding var showResetSheet: Bool
    let userEmail: String
    
    let userManager = UserManager.shared

    @State private var email: String
    @State private var isLoading = false
    @State private var message: String = ""
    @State var emailIsValid: Bool = true
    
    func validateEmail(_ email: String) -> Bool {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return false }

        let range = NSRange(email.startIndex..., in: email)
        let matches = detector.matches(in: email, options: [], range: range)

        return matches.first?.url?.scheme == "mailto"
    }

    // ✅ Proper init
    init(showResetSheet: Binding<Bool>, userEmail: String) {
     self._showResetSheet = showResetSheet
     self.userEmail = userEmail
     self._email = State(initialValue: userEmail)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                Text("Reset Password")
                    .font(.headline)
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)
            // MARK: - Content
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Enter your email and we’ll send you a password reset link.")
                    .font(.caption)
                    .foregroundStyle(Color.theme.gray)
                
                // Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(Color.theme.gray)
                    
                    TextField("Enter your email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color.theme.lightGray.opacity(0.15))
                        .cornerRadius(12)
                        .onChange(of: email) {
                            emailIsValid = validateEmail(email)
                        }
                    
                    Text("Invalid Format")
                        .font(.caption)
                        .foregroundStyle(Color.theme.darkRed)
                        .opacity(!emailIsValid && !email.isEmpty ? 1 : 0)
                        .padding(.horizontal, 12)
                }
                
                Spacer()
                
                if !message.isEmpty {
                    HStack(spacing: 2){
                        Text(message)
                            .font(.caption)
                        Image(systemName: message.contains("sent") ? "checkmark" : "xmark")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                // Send Button
                Button {
                    Task {
                        await sendReset()
                    }
                } label: {
                    if !isLoading {
                        Text("Send Reset Email")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.theme.darkBlue)
                            )
                    }
                    else {
                        HStack {
                            Spacer()
                            CircularLoadingView()
                                .frame(width: 20, height: 20)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.theme.darkBlue)
                        )
                    }
                }
                .disabled(email.isEmpty || isLoading || !emailIsValid)
                .opacity(email.isEmpty || !emailIsValid ? 0.5 : 1)
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color.theme.background.ignoresSafeArea())
        .presentationDetents([.medium])
    }
    
    private func sendReset() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await userManager.forgotPassword(email: email)
            message = "Reset email sent"
        } catch {
            message = error.localizedDescription
        }
    }
}

