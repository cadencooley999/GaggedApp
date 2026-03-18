//
//  NotificationsManager.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/4/26.
//
import SwiftUI
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

final class NotificationManager: NSObject, ObservableObject {
    
    @AppStorage("hasRequestedNotis") var hasRequestedNotis = false
    @AppStorage("hasEnabledNotifications") var hasEnabledNotifications = false
    
    @AppStorage("userId") var userId = ""
    @AppStorage("fcmToken") var lastFcmToken = ""
    
    @Published var hasAllowedNotifications: Bool = false

    static let shared = NotificationManager()
    
    
    private override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        print("🔄 App became active")
        checkIsAllowed()
    }

    // MARK: - Request permission if not asked
    func requestPermissionIfNeeded() {
        if !hasRequestedNotis {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                switch settings.authorizationStatus {
                case .notDetermined:
                    self?.requestNotificationPermission()
                    break
                case .denied:
                    break
                case .authorized, .provisional, .ephemeral:
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    self?.updateFirebaseNotificationsEnabled(allowed: true)
                    break
                @unknown default:
                    break
                }
                self?.hasRequestedNotis = true
            }
        }
    }

    // MARK: - Internal request
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.updateFirebaseNotificationsEnabled(allowed: true)
                }
            }

            if let error = error {
                print("Notification permission error:", error)
            }
        }
    }
    
    func checkIsAllowed() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.hasAllowedNotifications =
                    settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional ||
                    settings.authorizationStatus == .ephemeral
            }
        }
    }
    
    func updateFirebaseNotificationsEnabled(allowed: Bool) {
        let userRef = Firestore.firestore().collection("Users").document(userId)
        Task {
            do {
                // Save token for multi-device support
                try await userRef.updateData(["notificationsEnabled" : allowed])
                
            } catch {
                print("Error saving FCM token or notificationsEnabled:", error)
            }
        }
    }
}

// MARK: - Messaging Delegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        guard userId != "" else { return }
        guard token != lastFcmToken else {return}
        print("🔥 FCM token:", token)
        let userRef = Firestore.firestore().collection("Users").document(userId)
        Task {
            do {
                // Save token for multi-device support
                try await userRef.collection("FCMTokens").document(token).setData([
                    "platform": "ios",
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                lastFcmToken = token
                
                // Only set notificationsEnabled = true if it doesn't exist
                let doc = try await userRef.getDocument()
                if doc.data()?["notificationsEnabled"] == nil {
                    try await userRef.updateData(["notificationsEnabled": true])
                }
                
            } catch {
                print("Error saving FCM token or notificationsEnabled:", error)
            }
        }
    }
}

// MARK: - UNUserNotificationCenter Delegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // You can handle foreground notifications here if needed
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

