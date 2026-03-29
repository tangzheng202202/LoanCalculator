//
//  LoanModel.swift
//  LoanCalculator
//

import Foundation

struct LoanInput {
    enum RepaymentMethod: String, CaseIterable, Identifiable {
        case equalPayment = "等额本息"
        case equalPrincipal = "等额本金"
        case interestFirst = "先息后本"

        var id: Self { self }

        var displayName: String { rawValue }
    }

    /// 贷款金额（单位：万元）
    var loanAmount: Double = 100
    var loanTerm: Int = 30
    var annualRate: Double = 4.2
    var repaymentMethod: RepaymentMethod = .equalPayment

    /// 贷款金额（单位：元）
    var amountInYuan: Double {
        loanAmount * 10_000
    }
}

struct LoanResult {
    let monthlyPayment: Double
    let totalInterest: Double
    let totalPayment: Double
}

struct MonthlyDetail {
    let month: Int
    let payment: Double
    let principal: Double
    let interest: Double
    let remainingPrincipal: Double
}
