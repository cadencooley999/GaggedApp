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
    
    @FocusState private var passwordFocus: PasswordFieldFocus?
    enum PasswordFieldFocus: Hashable { case current, new }
    
    let userManager = UserManager.shared
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Subtitle / Requirements
                        Text("Your password must be at least 8 characters long, including a number and capital letter")
                            .font(.caption)
                            .foregroundStyle(Color.theme.trashcanGray)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(Color.theme.trashcanGray)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(Color.theme.darkBlue)
                                TextField("Enter account email", text: $emailText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChange(of: emailText) {
                                        emailText = emailText.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")
                                            .replacingOccurrences(of: "\n", with: "")
                                    }
                            }
                            .padding(14)
                            .glassEffect(.regular, in: .rect(cornerRadius: 18))
                        }
                        
                        // MARK: - Current Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Password")
                                .font(.caption)
                                .foregroundStyle(Color.theme.trashcanGray)
                            
                            HStack {
                                ZStack {
                                    TextField("Enter current password", text: $currentPassword)
                                        .focused($passwordFocus, equals: .current)
                                        .opacity(showCurrentPassword ? 1 : 0)
                                    SecureField("Enter current password", text: $currentPassword)
                                        .focused($passwordFocus, equals: .current)
                                        .opacity(showCurrentPassword ? 0 : 1)
                                }
                                .submitLabel(.done)
                                .frame(height: 20)
                                
                                Button {
                                    showCurrentPassword.toggle()
                                } label: {
                                    Image(systemName: showCurrentPassword ? "eye" : "eye.slash")
                                        .foregroundColor(Color.theme.trashcanGray)
                                        .frame(height: 20)
                                }
                            }
                            .padding(14)
                            .glassEffect(.regular, in: .rect(cornerRadius: 18))
                        }

                        // MARK: - New Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundStyle(Color.theme.trashcanGray)
                            
                            HStack {
                                ZStack {
                                    TextField("Enter new password", text: $newPassword)
                                        .focused($passwordFocus, equals: .new)
                                        .opacity(showNewPassword ? 1 : 0)
                                    SecureField("Enter new password", text: $newPassword)
                                        .focused($passwordFocus, equals: .new)
                                        .opacity(showNewPassword ? 0 : 1)
                                }
                                .submitLabel(.done)
                                .frame(height: 20)
                                .onChange(of: newPassword) {
                                    newPassword = newPassword.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")
                                        .replacingOccurrences(of: "\n", with: "")
                                    newPassword = String(newPassword.prefix(16))
                                    isNewPasswordValid = validatePassword(newPassword)
                                }
                                
                                Button {
                                    showNewPassword.toggle()
                                } label: {
                                    Image(systemName: showNewPassword ? "eye" : "eye.slash")
                                        .foregroundColor(Color.theme.trashcanGray)
                                        .frame(height: 20)
                                }
                            }
                            .padding(14)
                            .glassEffect(.regular, in: .rect(cornerRadius: 18))
                            
                            VStack(alignment: .leading, spacing: 4){
                                HStack {
                                    if passwordLength {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.theme.darkBlue)
                                            .font(.footnote)
                                    } else {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.theme.trashcanGray)
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
                                            .foregroundStyle(Color.theme.trashcanGray)
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
                                            .foregroundStyle(Color.theme.trashcanGray)
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
                            Task { await submitPasswordChange() }
                        } label: {
                            ZStack {
                                if isSubmitting {
                                    ProgressView().tint(Color.theme.background)
                                } else {
                                    Text("Confirm Password Change")
                                        .font(.headline)
                                        .foregroundStyle(Color.theme.background)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .glassEffect(.regular.tint(Color.theme.darkBlue), in: .rect(cornerRadius: 22))
                            .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)
                        }
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || isSubmitting || !isNewPasswordValid)
                        .opacity(currentPassword.isEmpty || newPassword.isEmpty || !isNewPasswordValid ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 72)
                    .padding(.bottom, 100)
                }
                .onScrollPhaseChange({ oldPhase, newPhase in
                    if newPhase == .interacting {
                        UIApplication.shared.endEditing()
                    }
                })
            }

            // Header overlay with blur pinned to top
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
            emailText = userEmail
        }
        .sheet(isPresented: $showResetSheet) {
            // Placeholder – you'll build this later
            ForgotPasswordSheet(showResetSheet: $showResetSheet, userEmail: userEmail)
        }
    }
    
    var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0){
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .glassEffect(.regular.interactive())
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
                    .opacity(0)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
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
    @State var timeout: Bool = true
    
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
                    .foregroundStyle(Color.theme.trashcanGray)
                
                // Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(Color.theme.trashcanGray)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .foregroundStyle(Color.theme.darkBlue)
                        TextField("Enter your email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .onChange(of: email) {
                                emailIsValid = validateEmail(email)
                            }
                    }
                    .padding(14)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
                    
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
                    ZStack {
                        if !isLoading {
                            Text("Send Reset Email")
                                .font(.headline)
                                .foregroundColor(Color.theme.background)
                        } else {
                            ProgressView().tint(Color.theme.background)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .glassEffect(.regular.tint(Color.theme.darkBlue), in: .rect(cornerRadius: 22))
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
            timeout = true
            message = "Reset email sent"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                timeout = false
            }
        } catch {
            message = error.localizedDescription
        }
    }
}

