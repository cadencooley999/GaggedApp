//
//  OnboardingView.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/26/25.
//

import SwiftUI
import PhotosUI

enum OnboardingTab {
    case policy
    case username
    case email
    case password
    case city
}

enum PageDirection {
    case forward
    case backward
}

struct OnboardingView: View {
    
    @EnvironmentObject var vm: OnboardingViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    
    @State private var usernameInput: String = ""
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State var showPassword: Bool = false
    @State var showUsernameError: Bool = false
    @State var showEmailError: Bool = false
    @State var passwordCapLetter: Bool = false
    @State var passwordNumber: Bool = false
    @State var passwordLength: Bool = false
    @State var submitError: String = ""
    @State var isSubmitLoading: Bool = false
    @State var usernameExistError: Bool = false
    
    @State private var pageDirection: PageDirection = .forward
    
    @State var welcomed: Bool = false
    
    let onboardingTabs: [OnboardingTab] = [.policy, .username, .email, .password, .city]
    
    @State var currentOnboardingTabIndex: Int = 0

    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            if welcomed {
                VStack {
                    onboardingPage
                        .transition(pageTransition)
                        .id(currentOnboardingTabIndex)
                }
                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85), value: currentOnboardingTabIndex)
                VStack {
                    header
                    Spacer()
                }
            }
            else {
                welcome
            }
        }
        .gesture(
            DragGesture(minimumDistance: 25, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height

                    // Make sure it's a horizontal swipe
                    guard abs(horizontal) > abs(vertical) else { return }

                    if horizontal < -50 {
                        onSwipeLeft()
                    } else if horizontal > 50 {
                        onSwipeRight()
                    }
                }
        )
    }
    
    @ViewBuilder
    var onboardingPage: some View {
        switch onboardingTabs[currentOnboardingTabIndex] {
        case .policy:
            policy
        case .username:
            username
        case .email:
            email
        case .password:
            password
        case .city:
            city
        }
    }
    
    var welcome: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Logo
            Image("AppImage")
                .resizable()
                .frame(width: 200, height: 200)
                .cornerRadius(22)

            // App Title
            Text("Gagged")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Welcome Header
            Text("Welcome")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            // Blurb (placeholder)
            Text("Built for gossipers and nosy internet slueths. Stay updated on your pool.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
//            VStack(alignment: .leading){
//                Text("Rule 1: NO posting straight guys")
//                Text("Rule 2: NO posting girls")
//                Text("Rule 3: NO dropping addresses and phone numbers")
//            }
//            .font(.body)
//            .foregroundColor(.secondary)
//            .padding(32)

            Spacer()
            
            Text("Already have an account? Log in here")
                .font(.subheadline)
                .foregroundStyle(Color.theme.darkBlue)
                .padding(.horizontal)
                .onTapGesture {
                    hasOnboarded = true
                }

            // Get Started Button
            Button(action: {
                welcomed = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.theme.darkBlue)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
    
    var policy: some View {
        VStack {
            Text("Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
            Button(action: {onSwipeLeft()}, label: {
                Text("Agree")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.theme.darkBlue)
                    .cornerRadius(10)
            })
        }
        .frame(maxWidth: .infinity)
        .background(Color.theme.background)
    }
    
    var username: some View {
        VStack {
            // TOP CONTENT
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a username")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This can be changed later.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextField("Username", text: $usernameInput)
                    .padding()
                    .background(Color.theme.lightGray.opacity(0.15))
                    .cornerRadius(12)
                    .onChange(of: usernameInput) {
                        usernameInput = usernameInput.replacing(" ", with: "")
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if showUsernameError {
                    Text("Not appropriate! Be good")
                        .font(.footnote)
                        .foregroundColor(Color.theme.darkRed)
                        .padding(.leading, 8)
                }
                
                if usernameExistError {
                    Text("Please enter a username")
                        .font(.footnote)
                        .foregroundColor(Color.theme.darkRed)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 96) // pushes it near the top

            Spacer()

            // BOTTOM BUTTONS
            HStack(spacing: 0) {
                Button(action: {
                    onSwipeRight()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.footnote)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.background.opacity(0.9))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.gray.opacity(0.4), lineWidth: 1)
                    )
                }
                
                Spacer()

                Button(action: {
                    onSwipeLeft()
                }) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.darkBlue)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
    
    var email: some View {
        VStack {
            // TOP CONTENT
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter an email")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Used for authentication and account recovery")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextField("Email", text: $emailInput)
                    .padding()
                    .background(Color.theme.lightGray.opacity(0.15))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: emailInput) {
                        emailInput = emailInput.replacingOccurrences(of: " ", with: "")
                    }
                if showEmailError {
                    Text("Email not valid")
                        .font(.footnote)
                        .foregroundColor(Color.theme.darkRed)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 96) // pushes it near the top

            Spacer()

            // BOTTOM BUTTONS
            HStack(spacing: 0) {
                Button(action: {
                    onSwipeRight()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.footnote)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.background.opacity(0.9))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.gray.opacity(0.4), lineWidth: 1)
                    )
                }
                
                Spacer()

                Button(action: {
                    onSwipeLeft()
                }) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.darkBlue)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
    
    var password: some View {
        VStack {
            // TOP CONTENT
            VStack(alignment: .leading, spacing: 12) {
                Text("Create a password")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Must be at least 8 characters, including a number and a capital letter.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                HStack {
                    Group {
                        if showPassword {
                            TextField("Password", text: $passwordInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $passwordInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    .padding()

                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye" : "eye.slash")
                            .foregroundStyle(Color.theme.gray.opacity(0.7))
                    }
                    .padding(.trailing, 12)
                }
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
            .padding(.horizontal)
            .padding(.top, 96)
            .onChange(of: passwordInput) {
                passwordInput = passwordInput.replacingOccurrences(of: " ", with: "")
                validatePassword(passwordInput)
            }

            Spacer()

            // BOTTOM BUTTONS (same as email)
            HStack(spacing: 0) {
                Button(action: {
                    onSwipeRight()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.footnote)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.background.opacity(0.9))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.gray.opacity(0.4), lineWidth: 1)
                    )
                }

                Spacer()

                Button(action: {
                    onSwipeLeft()
                }) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.darkBlue)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
    
    var city: some View {
        VStack {
            // TOP CONTENT
            VStack(alignment: .leading, spacing: 12) {
                Text("Enable location permissions to see posts near you")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("We use location based filtering to show you the most relevant posts")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                HStack(spacing: 0) {
                    if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                        if let city = locationManager.selectedCity {
                            cityRow(city: city, isRecent: false)
                        }
                    } else {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.subheadline.bold())
                            .foregroundColor(Color.theme.darkBlue)
                            .padding(8)
                        Text("Use Current Location")
                            .font(.body)
                            .foregroundStyle(Color.theme.darkBlue)
                    }
            
                    Spacer()
                    
//                    Image(systemName: locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted  ? "gear" :"arrow.clockwise")
//                        .font(.subheadline.bold())
//                        .foregroundColor(Color.theme.lightBlue)
//                        .padding(8)
                }
                .padding(.horizontal)
                .frame(height: 55)
                .background(
                    Rectangle()
                        .fill(Color.theme.background.opacity(0.001))
                        .onTapGesture {
                            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                Task {
                                    await locationManager.requestLocation()
                                }
                            }
                        }
                )
                .background(
                    Color.theme.lightGray.opacity(0.15)
                        .cornerRadius(15)
                )
            }
            .padding(.horizontal)
            .padding(.top, 96)

            Spacer()
            
            if submitError != "" {
                Text(submitError)
                    .font(.body)
                    .foregroundStyle(Color.theme.darkRed)
                    .padding(.bottom, 32)
                    .padding(.horizontal)
            }

            // BOTTOM BUTTONS (same as email)
            HStack(spacing: 0) {
                Button(action: {
                    onSwipeRight()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.footnote)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.background.opacity(0.9))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.gray.opacity(0.4), lineWidth: 1)
                    )
                }

                Spacer()

                Button(action: {
                    submitSignup()
                }) {
                    HStack(spacing: 6) {
                        if isSubmitLoading == false {
                            Text("Finish")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                        }
                        else {
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .opacity(0)
                            CircularLoadingView()
                                .frame(width: 20, height: 20)
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .opacity(0)
                        }
                    }
                    .padding(.horizontal, 52)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.theme.darkBlue)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
    
    var header: some View {
        HStack {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 2)
                    .foregroundStyle(currentOnboardingTabIndex >= index ? Color.theme.darkBlue : Color.theme.lightGray)
                    .padding(.horizontal, 4)
            }
        }
        .padding()
    }
    
    func onSwipeLeft() {
        guard currentOnboardingTabIndex < onboardingTabs.count - 1 else { return }
        pageDirection = .forward
        withAnimation {
            currentOnboardingTabIndex += 1
        }
    }

    func onSwipeRight() {
        guard currentOnboardingTabIndex > 0 else {
            pageDirection = .backward
            withAnimation {
                welcomed = false
            }
            return
        }
        pageDirection = .backward
        withAnimation {
            currentOnboardingTabIndex -= 1
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
    
    var pageTransition: AnyTransition {
        let goingForward = pageDirection == .forward

        return goingForward
        ? .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
          )
        : .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
          )
    }
    
    private func cityRow(city: City, isRecent: Bool) -> some View {
        HStack(spacing: 0) {
            
            Image(systemName: "mappin.and.ellipse")
                .font(.subheadline.bold())
                .foregroundColor(Color.theme.darkBlue)
                .padding(.trailing, 8)

            Text(city.city)
                .font(.body)

            Text(", \(city.state_id)")
                .font(.body)
                .italic()

            if isRecent {
                Text(" Recent")
                    .font(.caption)
                    .foregroundStyle(Color.theme.darkBlue)
                    .italic()
                    .padding(.leading, 16)
            }

            Spacer()

            if city.city == locationManager.selectedCity?.city {
                Image(systemName: "checkmark")
                    .font(.body)
                    .foregroundStyle(Color.theme.darkBlue)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 55)
        .background(
            Rectangle()
                .fill(Color.theme.background.opacity(0.001))
        )
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
    
    func validateEmail(_ email: String) -> Bool {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return false }

        let range = NSRange(email.startIndex..., in: email)
        let matches = detector.matches(in: email, options: [], range: range)

        return matches.first?.url?.scheme == "mailto"
    }
    
    func submitSignup() {
        Task {
            isSubmitLoading = true
            showEmailError = false
            showUsernameError = false
            usernameExistError = false
            let passvalid = validatePassword(passwordInput)
            let emailvalid = validateEmail(emailInput)
            let usernameAppropriate = ProfanityFilter.isUsernameClean(usernameInput)
            let usernameExist = usernameInput != ""
            if passvalid && emailvalid && usernameAppropriate && usernameExist {
                do {
                    try await vm.signInEmailAndPassword(email: emailInput, password: passwordInput, username: usernameInput)
                }
                catch {
                    submitError = error.localizedDescription
                }
            }
            else {
                pageDirection = .backward
                if passvalid != true {
                    currentOnboardingTabIndex = 3
                }
                if emailvalid != true {
                    showEmailError = true
                    currentOnboardingTabIndex = 2
                }
                if usernameAppropriate != true {
                    showUsernameError = true
                    currentOnboardingTabIndex = 1
                }
                if !usernameExist {
                    usernameExistError = true
                    currentOnboardingTabIndex = 1
                }
            }
            isSubmitLoading = false
        }
    }
}
