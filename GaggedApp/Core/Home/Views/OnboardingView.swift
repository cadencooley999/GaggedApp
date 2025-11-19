//
//  OnboardingView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/26/25.
//

import SwiftUI
import PhotosUI

struct OnboardingView: View {
    
    @EnvironmentObject var vm: OnboardingViewModel
    
    @State private var usernameInput: String = ""
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                Text("Welcome")
                    .font(.title)
                    .fontWeight(.bold)
                
                // MARK: - App Icon
                Image("AppImage")
                    .resizable()
                    .frame(width: 90, height: 90)
                    .cornerRadius(20)
                    .padding(.top, 20)
                
                // MARK: - Text Fields
                VStack(spacing: 15) {
                    customField("username", text: $usernameInput)
                    customField("email", text: $emailInput)
                    customSecureField("password", text: $passwordInput)
                }
                .padding(.horizontal)
                
                
                // MARK: - Create Account Button
                Button(action: {
                    Task {
                        try await vm.signInEmailAndPassword(
                            email: emailInput,
                            password: passwordInput,
                            username: usernameInput,
                            image: vm.pickedImage
                        )
                    }
                }) {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.darkBlue)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
        }
    }
    
    
    // MARK: - Custom Styled TextField
    func customField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.white.opacity(0.12))
            .cornerRadius(10)
            .foregroundColor(Color.theme.accent)
            .autocapitalization(.none)
    }
    
    // MARK: - Custom Styled SecureField
    func customSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding()
            .background(Color.white.opacity(0.12))
            .cornerRadius(10)
            .foregroundColor(Color.theme.accent)
            .autocapitalization(.none)
    }
}

#Preview {
    OnboardingView()
}
