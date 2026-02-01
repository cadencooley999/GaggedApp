//
//  KeyboardObserver.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/24/25.
//
import SwiftUI
import Foundation
import Combine

final class KeyboardObserver: ObservableObject {
    @Published private(set) var keyboardHeight: CGFloat = 0
    @Published private(set) var isVisible: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        let notifications = [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillHideNotification,
            UIResponder.keyboardWillChangeFrameNotification
        ]

        Publishers.MergeMany(
            notifications.map { NotificationCenter.default.publisher(for: $0) }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let self else { return }

            guard
                let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                let window = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow })
            else {
                self.keyboardHeight = 0
                self.isVisible = false
                return
            }

            // 🔑 THIS IS THE FIX
            let intersection = window.bounds.intersection(keyboardFrame)

            let height = max(0, intersection.height)
            
            print(height, "HEIGHT")

            self.keyboardHeight = height
            self.isVisible = height > 0
        }
        .store(in: &cancellables)
    }
}




