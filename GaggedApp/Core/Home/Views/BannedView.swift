import SwiftUI

struct BannedView: View {
    // The number of weeks remaining. Provide this from your logic layer.
    @AppStorage("expirationDate") var expirationDate = Date()
    @AppStorage("isLoggedIn") var isLoggedIn = false

    // Optional customization hooks if you have app-specific colors/assets.
    var title: String = "You have been banned"
    var subtitlePrefix: String = "Ban expires in"
    var iconName: String = "hand.raised.fill" // Change to match your brand if needed

    // Color scheme hooks: these attempt to use common asset names if present,
    // and fall back to system adaptive colors.
    var primaryColor: Color = Color.theme.darkBlue
    var backgroundMaterial: Material = .ultraThin

    // Hook for your sign out logic
    private func signOut() {
        Task {
            try await UserManager.shared.signOutUser()
            CoreDataManager.teardown()
            UserListenerManager.shared.stopUserListener()
            isLoggedIn = false
        }
    }
    
    var body: some View {
        ZStack {
            Background()
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(Color.theme.lightBlue.opacity(0.18))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.theme.lightGray.opacity(0.25), lineWidth: 1)
                            )

                        Image(systemName: iconName)
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundStyle(primaryColor)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 4)

                    // Title
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    // Subtitle with remaining duration
                    Text("\(subtitlePrefix) \(getDaysRemaining()) \(getDaysRemaining() == 1 ? "day" : "days")")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Optional guidance text
                    Text("If you believe this is a mistake, you can contact support or review our community guidelines.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)

                Spacer()
            }
            .padding(.bottom, 200)

            // Bottom-centered Sign Out button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        signOut()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.backward.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Sign Out")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundStyle(Color.theme.background)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(primaryColor)
                        )
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                        .contentShape(Capsule())
                        .accessibilityLabel("Sign out")
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .environment(\._lineHeightMultiple, 1.05)
    }
    
    func getDaysRemaining() -> Int {
        let now = Date()
        // If expirationDate is in the past, return 0
        guard expirationDate > now else { return 0 }
        // Calculate full days between now and expirationDate
        let startOfToday = Calendar.current.startOfDay(for: now)
        let startOfExpiration = Calendar.current.startOfDay(for: expirationDate)
        let components = Calendar.current.dateComponents([.day], from: startOfToday, to: startOfExpiration)
        return max(0, components.day ?? 0)
    }
}

