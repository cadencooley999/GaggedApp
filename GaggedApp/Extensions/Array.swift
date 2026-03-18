//
//  Array.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/24/26.
//

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Set {
    func chunked(into size: Int) -> [[Element]] {
        precondition(size > 0, "size must be greater than 0")
        var result: [[Element]] = []
        var start = startIndex
        while start != endIndex {
            let end = index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex
            let slice = self[start..<end]
            result.append(Array(slice))
            start = end
        }
        return result
    }
}
