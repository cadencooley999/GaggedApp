import SwiftUI

struct BlockedUsersView: View {
    
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var feedStore: FeedStore
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var pollsViewModel: PollsViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var leaderViewModel: LeaderViewModel
    
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Background()
            
            ScrollView {
                userList
                    .padding(.top, 86)
            }
            
            VStack {
                ZStack {
                    VStack {
                        BackgroundHelper.shared.appleHeaderBlur.frame(height: 88)
                        Spacer()
                    }
                    VStack {
                        header
                            .frame(height: 55)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .task {
            if !profileViewModel.blockedUsersLoaded {
                Task {
                    try await profileViewModel.getBlockedUsers()
                }
            }
        }
    }
    
    var header: some View {
        HStack {
            Image(systemName: "xmark")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            Spacer()
            Text("Blocked Users")
                .font(.headline)
            Spacer()
            // symmetry placeholder
            Image(systemName: "xmark")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .opacity(0)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(height: 55)
    }
        
    var userList: some View {
        VStack {
            ForEach(profileViewModel.blockedUsers) { user in
                userCard(user: user)
                    .padding(8)
            }
            if !profileViewModel.blockedUsersLoaded {
                ProgressView()
                    .padding(.top, 32)
            }
            if profileViewModel.blockedUsersLoaded && profileViewModel.blockedUsers.isEmpty {
                Text("You don't have anybody blocked. Probably a good thing.")
                    .font(.caption)
                    .foregroundStyle(Color.theme.trashcanGray)
                    .padding(.top, 32)
            }
        }
    }
    
    @ViewBuilder func userCard(user: UserModel) -> some View {
        HStack(spacing: 12) {
            // Profile image
            ProfilePic(address: user.imageAddress, size: 44)

            // Name and gags
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.accent)
                HStack(spacing: 6) {
                    Text("Gags:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(user.gags)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.accent)
                }
            }

            Spacer()

            // Unblock button
            Button {
                Task {
                    try await profileViewModel.unblockUser(userId: profileViewModel.userId, targetId: user.id)
                    profileViewModel.blockedUsers.removeAll(where: {$0.id == user.id})
                    feedStore.blocked.remove(user.id)
                    resetTheFeeds()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.slash")
                    Text("Unblock")
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.theme.darkRed)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.theme.lightGray.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 4)
    }
    
    func resetTheFeeds() {
        // Reset all feeds/state that can cache content
        homeViewModel.reset()
        pollsViewModel.reset()
        searchViewModel.resetGlobalPosts()
        searchViewModel.resetGlobalPolls()
        profileViewModel.resetSaved()
        postViewModel.resetRootComments()
        leaderViewModel.reset()
    }
}
