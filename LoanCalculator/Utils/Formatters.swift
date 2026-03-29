//
//  Formatters.swift
//  LoanCalculator
//

import Foundation

struct Formatters {
    static func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "¥0"
    }

    static func wanYuan(_ value: Double) -> String {
        String(format: "%.1f 万元", value)
    }
}
