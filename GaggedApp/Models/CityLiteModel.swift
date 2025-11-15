//
//  CityLiteModel.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/21/25.
//

import Foundation

struct CityLiteModel: Identifiable, Codable {
    let id: String
    let name: String
    let state: String
    let country: String
}
