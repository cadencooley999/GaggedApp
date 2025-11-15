//
//  UIApp.swift
//  CommonsDining
//
//  Created by Caden Cooley on 5/9/25.
//

import Foundation
import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
