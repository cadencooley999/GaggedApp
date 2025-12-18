//
//  City.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/10/25.
//
import Foundation
import SwiftUI

struct City: Codable, Identifiable, Equatable {
    let id: String
    let city: String
    let state_id: String
    let lat: Double
    let lng: Double
    
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.id == rhs.id
    }
}
