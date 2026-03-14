//
//  Item.swift
//  LoanCalculator
//
//  Created by mac on 2026/3/14.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
