//
//  SettingsViewModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 11/16/25.
//
import Foundation
import SwiftUI
import UserNotifications
import UIKit
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("userId") var userId = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    @AppStorage("hasRequestedNotis") var hasRequestedNotis = false
    @AppStorage("hasEnabledNotifications") var hasEnabledNotifications = false

    @Published var nameMentionNotifications: Bool = false
    @Published var nameToWatchFor: String = ""
    @Published var notificationToggle: Bool = false
    
    @Published var alertLoaded: Bool = false
    @Published var alertExists: Bool = false
    @Published var nameMentionCity: City? = nil
    
    let userManager = UserManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var hasAllowedNotifications: Bool = false
    
    var tempRemoteName: String = ""
    var tempRemoteCityId: String = ""
    
    init(manager: NotificationManager = .shared) {
        manager.$hasAllowedNotifications
            .sink { value in
                self.hasAllowedNotifications = value
                self.getNotiState()
            }
            .store(in: &cancellables)
        
        $nameToWatchFor
            .removeDuplicates()
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] value in
                if self?.alertLoaded != false {
                    if self?.tempRemoteName == "" {
                        self?.nameMentionNameEdited(name: value)
                    }
                    else {
                        self?.tempRemoteName = ""
                    }
                }
            }
            .store(in: &cancellables)
        
        $nameMentionCity
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] value in
                if self?.alertLoaded != false {
                    if self?.tempRemoteCityId == "" {
                        if let city = value {
                            self?.nameCityChanged(city: city)
                        }
                    }
                    else {
                        self?.tempRemoteCityId = ""
                    }
                }
            }
            .store(in: &cancellables)

    }
    
    func getNotiState() {
        if hasRequestedNotis {
            if hasEnabledNotifications && hasAllowedNotifications {
                notificationToggle = true
            }
            else {
                notificationToggle = false
            }
        }
        else {
            notificationToggle = false
        }
    }
    
    func setNotifications () {
        if !notificationToggle {
            if hasRequestedNotis {
                if hasAllowedNotifications {
                    hasEnabledNotifications = true
                    NotificationManager.shared.updateFirebaseNotificationsEnabled(allowed: true)
                    getNotiState()
                } else {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        DispatchQueue.main.async {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } else {
                NotificationManager.shared.requestPermissionIfNeeded()
            }
        } else {
            hasEnabledNotifications = false
            NotificationManager.shared.updateFirebaseNotificationsEnabled(allowed: false)
            getNotiState()
        }
    }
    
    func getNameAlertStateIfNeeded() {
        if !alertLoaded {
            Task { @MainActor in
                do {
                    print("getting alert state")
                    let alert = try await NameAlertManager.shared.getAlert(userId: userId)
                    print(alert)
                    tempRemoteName = alert.name
                    tempRemoteCityId = alert.cityId
                    nameToWatchFor = tempRemoteName
                    print(tempRemoteCityId)
                    nameMentionCity = CityManager.shared.getCity(id: tempRemoteCityId)
                    nameMentionNotifications = alert.isActive
                    alertExists = true
                    alertLoaded = true
                } catch NameAlertError.documentNotFound {
                    alertExists = false
                    alertLoaded = true
                } catch {
                    // Decide how you want to represent failure in UI:
                    alertExists = false
                    alertLoaded = true
                }
            }
        }
    }
    
    func nameMentionTapped() {
        guard alertLoaded else {return}
        if !alertExists {
            if nameToWatchFor != "" && nameMentionCity != nil{
                Task {
                    if let city = nameMentionCity {
                        try await NameAlertManager.shared.addAlert(alert: NameAlertModel(name: nameToWatchFor, normalizedName: nameToWatchFor.normalizedForIndexing(), isActive: true, userId: userId, cityId: city.id))
                        nameMentionNotifications = true
                        alertExists = true
                        alertLoaded = true
                    }
                }
            }
        }
        else {
            if nameMentionNotifications {
                Task {
                    try await NameAlertManager.shared.setAlertActive(userId: userId, isActive: false)
                    nameMentionNotifications = false
                }
            } else {
                Task {
                    try await NameAlertManager.shared.setAlertActive(userId: userId, isActive: true)
                    nameMentionNotifications = true
                }
            }
        }
    }
    
    func nameMentionNameEdited(name: String) {
        if alertExists {
            print("updating")
            Task {
                try await NameAlertManager.shared.changeAlertName(newName: name, userId: userId)
            }
        }
    }
    
    func nameCityChanged(city: City) {
        if alertExists {
            Task {
                try await NameAlertManager.shared.changeAlertCity(newCity: city.id, userId: userId)
            }
        }
    }
    
    func logOut(userId: String) {
        Task {
            try await userManager.signOutUser()
            CoreDataManager.teardown()
            UserListenerManager.shared.stopListening()
            isLoggedIn = false
        }
    }
    
    func deleteAccount(password: String) async throws -> Bool {
        do {
            try await userManager.reauthAndDelete(email: userEmail, password: password)
            CoreDataManager.teardown()
            UserListenerManager.shared.stopListening()
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

