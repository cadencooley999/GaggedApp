//
//  Text.swift
//  GaggedApp
//
//  Created by Caden Cooley on 10/11/25.
//
import Foundation


extension String {
    func clipped(to length: Int) -> String {
        if self.count > length {
            let endIndex = self.index(self.startIndex, offsetBy: length)
            return String(self[..<endIndex]) + "…"
        } else {
            return self
        }
    }
}

