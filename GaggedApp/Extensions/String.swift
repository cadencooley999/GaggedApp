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
    
    func normalizedForIndexing(removeSpaces: Bool = true) -> String {
            // 1️⃣ Lowercase
            var text = self.lowercased()

            // 2️⃣ Remove diacritics (é → e)
            text = text.folding(
                options: [.diacriticInsensitive, .widthInsensitive],
                locale: .current
            )

            // 3️⃣ Keep only letters, numbers, and spaces
            let allowed = CharacterSet.alphanumerics.union(.whitespaces)
            text = text.unicodeScalars
                .filter { allowed.contains($0) }
                .map(String.init)
                .joined()

            // 4️⃣ Collapse multiple spaces
            text = text.replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )

            // 5️⃣ Trim
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            // 6️⃣ Optional: remove spaces entirely (recommended for prefix matching)
            if removeSpaces {
                text = text.replacingOccurrences(of: " ", with: "")
            }

            return text
        }
}

