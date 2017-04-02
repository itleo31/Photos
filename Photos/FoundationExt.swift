//
//  FoundationExt.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation

extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

protocol StringType {
    var string: String { get }
}

extension String: StringType {
    var string: String { return self }
}

extension Optional where Wrapped: StringType {
    var isNotEmpty: Bool {
        if case let .some(value) = self {
            return value.string.isNotEmpty
        } else {
            return false
        }
    }
}

extension Date {
    func isSameDay(`as` anotherDate: Date) -> Bool {
        return NSCalendar.current.isDate(self, inSameDayAs: anotherDate)
    }
    
    func minutes(since anotherDate: Date) -> Int {
        return Int(self.timeIntervalSince(anotherDate)) / 60
    }
}



extension IndexSet {
    static func from(_ ints: [Int]) -> IndexSet {
        var indexSet = IndexSet()
        ints.forEach { indexSet.insert($0) }
        return indexSet
    }
}
