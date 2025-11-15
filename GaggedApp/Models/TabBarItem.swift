//
//  TabBarItem.swift
//  CommonsDining
//
//  Created by Caden Cooley on 5/5/25.
//

import Foundation
import SwiftUI

struct TabBarItem: Hashable {
    let iconName: String
    let title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}
