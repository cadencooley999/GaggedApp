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
    
    @State var usernameInput: String = ""
    @State var emailInput: String = ""
    @State var passwordInput: String = ""
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 40){
                Image(systemName: "AppIcon")
                TextField("Input Username", text: $usernameInput)
                TextField("Input Email", text: $emailInput)
                TextField("Input Password", text: $passwordInput)
                Circle()
                    .frame(width: 60, height: 60)
                    .overlay {
                        if let pickedImage = vm.pickedImage {
                            Image(uiImage: pickedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)// 👈 cap height here
                                .clipShape(Circle())                       // crop any overflow outside the frame
                        }
                        else {
                            Rectangle()
                                .fill(Color.theme.background)
                                .frame(width: 300)
                                .frame(height: 350)
                        }
                        HStack {
                            if vm.pickedImage == nil {
                                PhotosPicker(selection: $vm.imageSelection, matching: .any(of: [.images])) {
                                    Image(systemName: "camera")
                                        .font(.title3)
                                        .foregroundStyle(Color.theme.darkBlue)
                                }
                            }
                        }
                        if vm.pickedImage != nil {
                            VStack {
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.theme.brightRed)
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                                    .onTapGesture {
                                        if vm.pickedImage != nil {
                                            vm.pickedImage = nil
                                        }
                                    }
                                    .padding()
                            }
                        }
                    }
                Rectangle()
                    .fill(Color.theme.darkBlue)
                    .onTapGesture {
                        if let selectedImage = vm.pickedImage {
                            Task {
                                try await vm.signInEmailAndPassword(email: emailInput, password: passwordInput, username: usernameInput, image: selectedImage)
                            }
                        }
                        else {
                            Task {
                                try await vm.signInEmailAndPassword(email: emailInput, password: passwordInput, username: usernameInput, image: nil)
                            }
                        }
                    }
            }
            
        }
    }
}

#Preview {
    OnboardingView()
}
