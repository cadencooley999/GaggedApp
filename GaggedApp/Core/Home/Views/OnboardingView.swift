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
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.openURL) var openURL
    
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
    
    let onboardingTabs: [OnboardingTab] = [.username, .email, .password, .city, .policy]
    
    @FocusState private var focusedField: Field?
    enum Field { case username, email, password }
    
    @State var currentOnboardingTabIndex: Int = 0

    var body: some View {
        ZStack {
            Background()
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
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focusedField = nil
                    }                }
        case .username:
            username
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focusedField = .username
                    }
                }
        case .email:
            email
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focusedField = .email
                    }
                }
        case .password:
            password
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focusedField = .password
                    }
                }
        case .city:
            city
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focusedField = nil
                    }
                }
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
                withAnimation(.easeInOut(duration: 0.3)) {
                    welcomed = true
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(Color.theme.background)
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
            // TOP CONTENT
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.theme.lightBlue.opacity(0.18))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.theme.lightGray.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color.theme.darkBlue)
                        .symbolRenderingMode(.hierarchical)
                }

                Text("By signing up you agree to the Terms of Service and Privacy Policy.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Please review the following documents:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 96)

            // LINKS LIST
            VStack(spacing: 12) {
                policyLinkRow(title: "Terms of Service")
                    .contentShape(Rectangle())
                    .onTapGesture {
                            openURL(URL(string: "https://gaggedapp.web.app/legal/terms.html") ?? URL(string: "https://www.apple.com/")!, prefersInApp: true)
                    }
                policyLinkRow(title: "Privacy Policy")
                    .contentShape(Rectangle())
                    .onTapGesture {
                            openURL(URL(string: "https://gaggedapp.web.app/legal/privacy.html") ?? URL(string: "https://www.apple.com/")!, prefersInApp: true)
                    }
                policyLinkRow(title: "Community Guidelines")
                    .contentShape(Rectangle())
                    .onTapGesture {
                            openURL(URL(string: "https://gaggedapp.web.app/legal/community.html") ?? URL(string: "https://www.apple.com/")!, prefersInApp: true)
                    }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            if submitError != "" {
                Text(submitError)
                    .font(.body)
                    .foregroundStyle(Color.theme.darkRed)
                    .padding(.bottom, 8)
                    .padding(.horizontal)
            }

            // FULL-WIDTH AGREE BUTTON
            Button(action: {
                submitSignup()
            }) {
                HStack {
                    if isSubmitLoading == false {
                        Text("Agree & Sign Up")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    } else {
                        CircularLoadingView(color: Color.theme.background)
                            .frame(width: 20, height: 20)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.theme.darkBlue)
                )
            }
            .foregroundColor(Color.theme.background)
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
            .disabled(isSubmitLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .focused($focusedField, equals: .username)
                    .glassEffect()
                    .onChange(of: usernameInput, {
                        usernameInput = usernameInput.replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: "\t", with: "")
                            .replacingOccurrences(of: "\n", with: "")
                        usernameInput = String(usernameInput.prefix(12))
                    })
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

            OnboardingBottomButtons(onBack: { onSwipeRight() }, onNext: { onSwipeLeft() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .focused($focusedField, equals: .email)
                    .glassEffect()
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: emailInput, {
                        emailInput = emailInput.replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: "\t", with: "")
                            .replacingOccurrences(of: "\n", with: "")
                    })
                if showEmailError {
                    Text("Invalid email")
                        .font(.footnote)
                        .foregroundColor(Color.theme.darkRed)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 96) // pushes it near the top

            Spacer()

            OnboardingBottomButtons(onBack: { onSwipeRight() }, onNext: { onSwipeLeft() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    ZStack {
                        TextField("Password", text: $passwordInput)
                            .focused($focusedField, equals: .password)
                            .opacity(showPassword ? 1 : 0)
                        SecureField("Password", text: $passwordInput)
                            .focused($focusedField, equals: .password)
                            .opacity(showPassword ? 0 : 1)
                    }
                    .submitLabel(.done)
                    .frame(height: 20)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
                    .id("password")
                    .onChange(of: passwordInput, {
                        passwordInput = passwordInput.replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: "\t", with: "")
                            .replacingOccurrences(of: "\n", with: "")
                        passwordInput = String(passwordInput.prefix(16))
                    })

                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye" : "eye.slash")
                            .foregroundStyle(Color.theme.gray.opacity(0.7))
                    }
                    .padding(.trailing, 12)
                }
                .glassEffect()
                
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

            OnboardingBottomButtons(onBack: { onSwipeRight() }, onNext: { onSwipeLeft() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        else {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.theme.darkBlue)
                                .padding(8)
                            Text("Use Current Location")
                                .font(.body)
                                .foregroundStyle(Color.theme.darkBlue)
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
                                    try await locationManager.requestLocation()
                                }
                            }
                        }
                )
                .glassEffect()
            }
            .padding(.horizontal)
            .padding(.top, 96)

            Spacer()
            
            OnboardingBottomButtons(onBack: { onSwipeRight() }, onNext: { onSwipeLeft() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                UIApplication.shared.endEditing()
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
            .background(Color.theme.background.opacity(0.12))
            .cornerRadius(10)
            .foregroundColor(Color.theme.accent)
            .autocapitalization(.none)
    }
    
    // MARK: - Custom Styled SecureField
    func customSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding()
            .background(Color.theme.background.opacity(0.12))
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
    }
    
    private func policyLinkRow(title: String) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "doc.text")
                .font(.subheadline.bold())
                .foregroundColor(Color.theme.darkBlue)
                .padding(8)

            Text(title)
                .font(.body)
                .foregroundStyle(Color.theme.accent)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Color.theme.gray.opacity(0.6))
                .padding(8)
        }
        .padding(.horizontal)
        .frame(height: 55)
        .glassEffect()
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
        guard !email.isEmpty else { return false }
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
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
                    try await vm.signInEmailAndPassword(email: emailInput, password: passwordInput, username: usernameInput.replacingOccurrences(of: "  ", with: ""))
                }
                catch {
                    submitError = error.localizedDescription
                }
            }
            else {
                // Determine which page to return to based on validation failures
                var targetIndex = currentOnboardingTabIndex

                // Determine the earliest invalid step and jump there
                if !usernameExist || !usernameAppropriate {
                    showUsernameError = !usernameAppropriate
                    usernameExistError = !usernameExist
                    targetIndex = 0
                } else if !emailvalid {
                    showEmailError = true
                    targetIndex = 1
                } else if !passvalid {
                    targetIndex = 2
                }
                // Animate as a backward transition (slide right) from Policy back to the required page
                pageDirection = .backward
                withAnimation {
                    currentOnboardingTabIndex = targetIndex
                }
            }
            isSubmitLoading = false
        }
    }
    
    // MARK: - Reusable Bottom Buttons
    struct OnboardingBottomButtons: View {
        var onBack: () -> Void
        var onNext: () -> Void

        var body: some View {
            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let buttonWidth = max(140, totalWidth / 3) // about a third, with a sensible minimum

                HStack(spacing: 16) {
                    Button(action: { onBack() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.footnote)
                            Text("Back")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(Color.theme.gray.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.theme.background.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .blur(radius: 2)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.theme.lightGray.opacity(0.35), lineWidth: 1)
                        )
                        .contentShape(Capsule())
                    }
                    .frame(width: buttonWidth, height: 55)

                    Spacer()

                    Button(action: { onNext() }) {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                        }
                        .foregroundColor(Color.theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.theme.darkBlue)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.theme.darkBlue.opacity(0.001), lineWidth: 1)
                        )
                        .contentShape(Capsule())
                    }
                    .frame(width: buttonWidth, height: 55)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 55)
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
        }
    }
}

