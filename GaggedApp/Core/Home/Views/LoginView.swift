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
    
    
    @State private var email = ""
    @State private var password = ""
    @State var failure: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                if failure {
                    Text("Login failed, please try again")
                        .font(.body)
                        .foregroundStyle(Color.theme.darkRed)
                        .fontWeight(.bold)
                        .padding()
                }

                // Email field
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.theme.lightGray.opacity(0.2))
                    .cornerRadius(10)
                
                // Password field
                SecureField("Password", text: $password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.theme.lightGray.opacity(0.2))
                    .cornerRadius(10)
                
                Button(action: {
                    Task {
                        let success = await loginViewModel.login(email: email, password: password)
                        if success {
                            isLoggedIn = true
                        }
                        else {
                            failure = true
                        }
                    }
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.accent)
                        .cornerRadius(10)
                    
                }
                .padding(.top, 10)
                
                // Create Account button
                Button(action: {
                    // Call your create account logic here
                    print("Create Account tapped")
                }) {
                    Text("Create Account")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.accent)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
