//
//  LoginView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/16/25.
//


import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasOnboarded") var hasOnboarded = false
    @AppStorage("userId") var userId = ""
    
    @State private var email = ""
    @State private var password = ""
    @State var failure: Bool = false
    @State var showPassword: Bool = false
    @State var showResetSheet: Bool = false
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }

            VStack(spacing: 24) {
                Spacer()

                // App Icon
                Image("AppImage")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .cornerRadius(22)

                // App Title
                Text("Gagged")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if failure {
                    Text("Login failed, please try again")
                        .font(.footnote)
                        .foregroundStyle(Color.theme.darkRed)
                }

                // Email
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.theme.lightGray.opacity(0.15))
                    .cornerRadius(12)

                // Password with eye
                VStack {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .frame(height: 20)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .frame(height: 20)
                                .foregroundStyle(Color.theme.gray.opacity(0.7))
                        }
                        .padding(.trailing, 12)
                    }
                    .background(Color.theme.lightGray.opacity(0.15))
                    .cornerRadius(12)
                    
                    Text("Forgot Password?")
                        .font(.caption)
                        .foregroundStyle(Color.theme.darkBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            showResetSheet = true
                        }
                        .padding(.leading, 4)
                        .padding(.top, 2)
                    
                }

                // Login Button
                Button {
                    Task {
                        let success = await loginViewModel.login(
                            email: email,
                            password: password
                        )
                        failure = !success
                        if success { isLoggedIn = true }
                    }
                } label: {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.theme.darkBlue)
                        )
                }
                .padding(.top, 8)

                // Create Account
                Button {
                    withAnimation(.easeInOut) {
                        hasOnboarded = false
                        userId = ""
                    }
                } label: {
                    Text("Create Account")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.darkBlue)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .gesture(
            DragGesture()
                .onEnded { _ in
                    UIApplication.shared.endEditing()
                }
        )
        .sheet(isPresented: $showResetSheet) {
            // Placeholder – you'll build this later
            ForgotPasswordSheet(showResetSheet: $showResetSheet, userEmail: email)
        }
    }

}
