//
//  CalculationEngine.swift
//  LoanCalculator
//

import Foundation

class CalculationEngine {
    static func calculate(input: LoanInput) -> LoanResult {
        let schedule = schedule(input: input)
        let totalPayment = schedule.reduce(0) { $0 + $1.payment }
        let totalInterest = schedule.reduce(0) { $0 + $1.interest }

        return LoanResult(
            monthlyPayment: schedule.first?.payment ?? 0,
            totalInterest: totalInterest,
            totalPayment: totalPayment
        )
    }

    static func schedule(input: LoanInput) -> [MonthlyDetail] {
        let principal = input.amountInYuan
        let months = input.loanTerm * 12
        let monthlyRate = input.annualRate / 100 / 12

        guard months > 0 else { return [] }

        // Zero interest (or zero rate) -> 等额本金
        if monthlyRate <= 0 {
            let monthlyPrincipal = principal / Double(months)
            return (1...months).map { month in
                let remaining = principal - monthlyPrincipal * Double(month)
                return MonthlyDetail(
                    month: month,
                    payment: monthlyPrincipal,
                    principal: monthlyPrincipal,
                    interest: 0,
                    remainingPrincipal: max(0, remaining)
                )
            }
        }

        switch input.repaymentMethod {
        case .equalPayment:
            return scheduleEqualPayment(principal: principal, months: months, monthlyRate: monthlyRate)
        case .equalPrincipal:
            return scheduleEqualPrincipal(principal: principal, months: months, monthlyRate: monthlyRate)
        case .interestFirst:
            return scheduleInterestFirst(principal: principal, months: months, monthlyRate: monthlyRate)
        }
    }

    private static func scheduleEqualPayment(principal: Double, months: Int, monthlyRate: Double) -> [MonthlyDetail] {
        let power = pow(1 + monthlyRate, Double(months))
        let monthlyPayment = principal * monthlyRate * power / (power - 1)

        var remainingPrincipal = principal
        var details: [MonthlyDetail] = []

        for month in 1...months {
            let interest = remainingPrincipal * monthlyRate
            let principalPaid = monthlyPayment - interest
            remainingPrincipal -= principalPaid

            details.append(
                MonthlyDetail(
                    month: month,
                    payment: monthlyPayment,
                    principal: principalPaid,
                    interest: interest,
                    remainingPrincipal: max(0, remainingPrincipal)
                )
            )
        }

        return details
    }

    private static func scheduleEqualPrincipal(principal: Double, months: Int, monthlyRate: Double) -> [MonthlyDetail] {
        let monthlyPrincipal = principal / Double(months)
        var remainingPrincipal = principal
        var details: [MonthlyDetail] = []

        for month in 1...months {
            let interest = remainingPrincipal * monthlyRate
            let payment = monthlyPrincipal + interest
            remainingPrincipal -= monthlyPrincipal

            details.append(
                MonthlyDetail(
                    month: month,
                    payment: payment,
                    principal: monthlyPrincipal,
                    interest: interest,
                    remainingPrincipal: max(0, remainingPrincipal)
                )
            )
        }

        return details
    }

    private static func scheduleInterestFirst(principal: Double, months: Int, monthlyRate: Double) -> [MonthlyDetail] {
        let monthlyInterest = principal * monthlyRate
        var details: [MonthlyDetail] = []

        for month in 1...months {
            let payment: Double
            let principalPaid: Double
            let remaining: Double

            if month < months {
                payment = monthlyInterest
                principalPaid = 0
                remaining = principal
            } else {
                payment = monthlyInterest + principal
                principalPaid = principal
                remaining = 0
            }

            details.append(
                MonthlyDetail(
                    month: month,
                    payment: payment,
                    principal: principalPaid,
                    interest: monthlyInterest,
                    remainingPrincipal: remaining
                )
            )
        }

        return details
    }
}
