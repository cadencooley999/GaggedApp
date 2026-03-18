//
//  LoginView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/16/25.
//


import SwiftUI

enum emailPassFocus: String, Hashable {
    case email = "email"
    case password = "password"
}

struct LoginView: View {
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasOnboarded") var hasOnboarded = false
    @AppStorage("userId") var userId = ""
    
    @State private var email = ""
    @State private var password = ""
    @State var failure: Bool = false
    @State var showPassword: Bool = false
    @State var showResetSheet: Bool = false
    @State var isProgrammatic: Bool = true
    
    @FocusState var emailPassFocused: emailPassFocus?
    
    var body: some View {
        ZStack {
            Background()
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false){
                    VStack(spacing: 24) {
                        Spacer()

                        // App Icon
                        Image("AppImage")
                            .resizable()
                            .frame(width: 172, height: 172)
                            .cornerRadius(22)
                        
                            .padding(.vertical)

                        // App Title
                        Text("Gagged")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Login failed, please try again")
                            .font(.footnote)
                            .foregroundStyle(Color.theme.darkRed)
                            .opacity(failure ? 1 : 0)

                        // Email
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .glassEffect()
                            .id("email")
                            .focused($emailPassFocused, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    emailPassFocused = .password
                                }
                            }

                        // Password with eye
                        VStack {
                            HStack {
                                ZStack {
                                    TextField("Password", text: $password)
                                        .focused($emailPassFocused, equals: .password)
                                        .opacity(showPassword ? 1 : 0)
                                    SecureField("Password", text: $password)
                                        .focused($emailPassFocused, equals: .password)
                                        .opacity(showPassword ? 0 : 1)
                                }
                                .submitLabel(.done)
                                .frame(height: 20)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .id("password")

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye" : "eye.slash")
                                        .frame(height: 20)
                                        .foregroundStyle(Color.theme.gray.opacity(0.7))
                                }
                                .padding(.trailing, 12)
                            }
                            .glassEffect()
                            
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
                                failure = false
                                let success = await loginViewModel.login(
                                    email: email,
                                    password: password
                                )
                                failure = !success
                                if success {
                                    isLoggedIn = true
                                    UserListenerManager.shared.startListening()
                                }
                            }
                        } label: {
                            Text("Login")
                                .font(.headline)
                                .foregroundColor(Color.theme.background)
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
                .animation(.easeInOut(duration: 0.25), value: emailPassFocused)
                .onChange(of: emailPassFocused) { newValue in
                    if let target = newValue {
                        isProgrammatic = true
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(target.rawValue, anchor: .center)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            isProgrammatic = false
                        })
                    }
                }
            }
            .onScrollPhaseChange { _, _ in
                guard !isProgrammatic else {return}
                UIApplication.shared.endEditing()
            }
        }
        .sheet(isPresented: $showResetSheet) {
            // Placeholder – you'll build this later
            ForgotPasswordSheet(showResetSheet: $showResetSheet, userEmail: email)
        }
    }

}
