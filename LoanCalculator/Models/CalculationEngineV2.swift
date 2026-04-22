//
//  CalculationEngineV2.swift
//  LoanCalculator
//
//  扩展的计算引擎（支持组合贷款）
//

import Foundation

/// 组合贷款计算引擎
class CalculationEngineV2 {
    
    // MARK: - 主计算入口
    static func calculate(input: LoanInputV2) -> LoanResultV2 {
        // 复制输入进行计算（避免 mutating 问题）
        var inputCopy = input
        let (hfLoan, cmLoan) = calculateLoanAmounts(input: inputCopy)
        
        var result = LoanResultV2(
            totalMonthlyPayment: 0,
            totalPayment: 0,
            totalInterest: 0,
            housingFundMonthlyPayment: 0,
            housingFundTotalInterest: 0,
            housingFundTotalPayment: 0,
            housingFundPrincipal: hfLoan,
            commercialMonthlyPayment: 0,
            commercialTotalInterest: 0,
            commercialTotalPayment: 0,
            commercialPrincipal: cmLoan,
            loanTerm: input.loanTerm,
            loanAmount: input.loanAmount,
            loanType: input.loanType,
            city: input.city,
            commercialRate: input.commercialRate
        )
        
        switch input.loanType {
        case .commercial:
            let cmResult = calcCommercial(principal: cmLoan, annualRate: input.commercialRate, months: input.loanTerm * 12, method: input.repaymentMethod)
            result.commercialMonthlyPayment = cmResult.monthlyPayment
            result.commercialTotalInterest = cmResult.totalInterest
            result.commercialTotalPayment = cmResult.totalPayment
            
            result.totalMonthlyPayment = cmResult.monthlyPayment
            result.totalInterest = cmResult.totalInterest
            result.totalPayment = cmResult.totalPayment
            
        case .housingFund:
            let hfResult = calcHousingFund(principal: hfLoan, annualRate: input.housingFundRate, months: input.loanTerm * 12, method: input.repaymentMethod)
            result.housingFundMonthlyPayment = hfResult.monthlyPayment
            result.housingFundTotalInterest = hfResult.totalInterest
            result.housingFundTotalPayment = hfResult.totalPayment
            
            result.totalMonthlyPayment = hfResult.monthlyPayment
            result.totalInterest = hfResult.totalInterest
            result.totalPayment = hfResult.totalPayment
            
        case .combined:
            // 公积金部分
            let hfResult = calcHousingFund(principal: hfLoan, annualRate: input.housingFundRate, months: input.loanTerm * 12, method: input.repaymentMethod)
            result.housingFundMonthlyPayment = hfResult.monthlyPayment
            result.housingFundTotalInterest = hfResult.totalInterest
            result.housingFundTotalPayment = hfResult.totalPayment
            
            // 商业贷款部分
            let cmResult = calcCommercial(principal: cmLoan, annualRate: input.commercialRate, months: input.loanTerm * 12, method: input.repaymentMethod)
            result.commercialMonthlyPayment = cmResult.monthlyPayment
            result.commercialTotalInterest = cmResult.totalInterest
            result.commercialTotalPayment = cmResult.totalPayment
            
            // 合计
            result.totalMonthlyPayment = hfResult.monthlyPayment + cmResult.monthlyPayment
            result.totalInterest = hfResult.totalInterest + cmResult.totalInterest
            result.totalPayment = hfResult.totalPayment + cmResult.totalPayment
        }
        
        return result
    }
    
    // MARK: - 月度明细
    static func schedule(input: LoanInputV2) -> [MonthlyScheduleItemV2] {
        let (hfLoan, cmLoan) = calculateLoanAmounts(input: input)
        let months = input.loanTerm * 12
        let hfRate = input.housingFundRate / 12
        let cmRate = input.commercialRate / 12
        let method = input.repaymentMethod
        
        // 分别计算公积金和商贷的月度明细
        let hfItems = generateSchedule(principal: hfLoan, monthlyRate: hfRate, months: months, method: method)
        let cmItems = generateSchedule(principal: cmLoan, monthlyRate: cmRate, months: months, method: method)
        
        // 合并两部分的明细
        var items: [MonthlyScheduleItemV2] = []
        for i in 0..<months {
            let hf = hfItems[i]
            let cm = cmItems[i]
            let remaining = max(0, hf.remaining + cm.remaining)
            
            items.append(MonthlyScheduleItemV2(
                month: i + 1,
                totalPayment: hf.payment + cm.payment,
                totalPrincipal: hf.principal + cm.principal,
                totalInterest: hf.interest + cm.interest,
                remainingPrincipal: remaining,
                housingFundPayment: hfLoan > 0 ? hf.payment : 0,
                housingFundPrincipal: hfLoan > 0 ? hf.principal : 0,
                housingFundInterest: hfLoan > 0 ? hf.interest : 0,
                commercialPayment: cmLoan > 0 ? cm.payment : 0,
                commercialPrincipal: cmLoan > 0 ? cm.principal : 0,
                commercialInterest: cmLoan > 0 ? cm.interest : 0
            ))
        }
        
        return items
    }
    
    // MARK: - 私有辅助类型
    private struct ScheduleItem {
        var payment: Double
        var principal: Double
        var interest: Double
        var remaining: Double
    }
    
    // MARK: - 生成单一部分的月度明细
    private static func generateSchedule(principal: Double, monthlyRate: Double, months: Int, method: RepaymentMethod) -> [ScheduleItem] {
        guard principal > 0 else {
            return Array(repeating: ScheduleItem(payment: 0, principal: 0, interest: 0, remaining: 0), count: months)
        }
        
        var items: [ScheduleItem] = []
        
        switch method {
        case .equalPayment:
            let power = pow(1 + monthlyRate, Double(months))
            let monthlyPayment = principal * monthlyRate * power / (power - 1)
            var remaining = principal
            
            for month in 1...months {
                let interest = remaining * monthlyRate
                let principalPaid = monthlyPayment - interest
                remaining -= principalPaid
                
                if month == months { remaining = 0 }
                
                items.append(ScheduleItem(
                    payment: monthlyPayment,
                    principal: principalPaid,
                    interest: interest,
                    remaining: max(0, remaining)
                ))
            }
            
        case .equalPrincipal:
            let monthlyPrincipal = principal / Double(months)
            
            for month in 1...months {
                let interest = (principal - monthlyPrincipal * Double(month - 1)) * monthlyRate
                let payment = monthlyPrincipal + interest
                let remaining = month == months ? 0 : (principal - monthlyPrincipal * Double(month))
                
                items.append(ScheduleItem(
                    payment: payment,
                    principal: monthlyPrincipal,
                    interest: interest,
                    remaining: max(0, remaining)
                ))
            }
            
        case .interestFirst:
            let monthlyInterest = principal * monthlyRate
            
            for month in 1...months {
                if month < months {
                    items.append(ScheduleItem(
                        payment: monthlyInterest,
                        principal: 0,
                        interest: monthlyInterest,
                        remaining: principal
                    ))
                } else {
                    items.append(ScheduleItem(
                        payment: monthlyInterest + principal,
                        principal: principal,
                        interest: monthlyInterest,
                        remaining: 0
                    ))
                }
            }
        }
        
        return items
    }
    
    // MARK: - 私有方法
    
    /// 计算公积金和商贷金额
    private static func calculateLoanAmounts(input: LoanInputV2) -> (housingFund: Double, commercial: Double) {
        let totalLoan = input.loanAmount
        let housingFundLoanable = calculateHousingFundLoanable(input: input)
        
        switch input.loanType {
        case .commercial:
            return (0, totalLoan)
            
        case .housingFund:
            let hfLoan = min(housingFundLoanable, totalLoan)
            return (hfLoan, 0)
            
        case .combined:
            let hfLoan = min(housingFundLoanable, totalLoan)
            let cmLoan = totalLoan - hfLoan
            return (hfLoan, cmLoan)
        }
    }
    
    /// 计算公积金可贷额度
    private static func calculateHousingFundLoanable(input: LoanInputV2) -> Double {
        let balance = input.housingFundBalance + (input.spouseHousingFund ? input.spouseHousingFundBalance : 0)
        return input.city.calculateHousingFundLoanable(
            balance: balance,
            spouseBalance: input.spouseHousingFund ? input.spouseHousingFundBalance : 0,
            housePrice: input.totalHousePrice,
            houseType: input.houseType
        )
    }
    
    private static func calcLoan(principal: Double, annualRate: Double, months: Int, method: RepaymentMethod) -> (monthlyPayment: Double, totalPayment: Double, totalInterest: Double) {
        guard principal > 0 && months > 0 else {
            return (0, 0, 0)
        }
        
        let monthlyRate = annualRate / 12
        
        switch method {
        case .equalPayment:
            let power = pow(1 + monthlyRate, Double(months))
            let monthlyPayment = principal * monthlyRate * power / (power - 1)
            let totalPayment = monthlyPayment * Double(months)
            let totalInterest = totalPayment - principal
            return (monthlyPayment, totalPayment, totalInterest)
            
        case .equalPrincipal:
            let monthlyPrincipal = principal / Double(months)
            var totalInterest: Double = 0
            var remaining = principal
            
            for _ in 1...months {
                let interest = remaining * monthlyRate
                totalInterest += interest
                remaining -= monthlyPrincipal
            }
            
            let firstPayment = monthlyPrincipal + principal * monthlyRate
            let totalPayment = principal + totalInterest
            
            return (firstPayment, totalPayment, totalInterest)
            
        case .interestFirst:
            let monthlyInterest = principal * monthlyRate
            let totalInterest = monthlyInterest * Double(months)
            let totalPayment = principal + totalInterest
            return (monthlyInterest, totalPayment, totalInterest)
        }
    }
    
    private static func calcCommercial(principal: Double, annualRate: Double, months: Int, method: RepaymentMethod) -> (monthlyPayment: Double, totalPayment: Double, totalInterest: Double) {
        return calcLoan(principal: principal, annualRate: annualRate, months: months, method: method)
    }
    
    private static func calcHousingFund(principal: Double, annualRate: Double, months: Int, method: RepaymentMethod) -> (monthlyPayment: Double, totalPayment: Double, totalInterest: Double) {
        return calcLoan(principal: principal, annualRate: annualRate, months: months, method: method)
    }

    // MARK: - Prepayment Optimization

    /// Prepayment scenario result
    struct PrepaymentScenario {
        let prepaymentAmount: Double        // 提前还款金额（元）
        let monthsSaved: Int                // 节省月数
        let interestSaved: Double           // 节省利息（元）
        let newMonthlyPayment: Double?      // 新月供（缩短期限时不变）
        let newLoanTermMonths: Int?         // 新期限月数
        let remainingPrincipal: Double      // 剩余本金
        let label: String                   // 场景标签
    }

    /// Calculate prepayment savings by reducing loan term
    static func calculatePrepayment(
        originalInput: LoanInputV2,
        prepaymentAmount: Double,
        reduceTerm: Bool,
        monthlySurplus: Double = 0
    ) -> PrepaymentScenario {
        let originalSchedule = schedule(input: originalInput)
        let months = originalInput.loanTerm * 12
        // Find current remaining principal (after 12 months of payments by default)
        let currentMonth = min(12, months)
        let remainingAtStart = originalSchedule.isEmpty ? originalInput.loanAmount : originalSchedule[min(currentMonth - 1, originalSchedule.count - 1)].remainingPrincipal

        let remainingAfterPrepayment = max(0, remainingAtStart - prepaymentAmount)

        // Simulate new loan with remaining principal by adjusting house price
        let newInput = LoanInputV2()
        newInput.loanType = originalInput.loanType
        newInput.city = originalInput.city
        newInput.houseType = originalInput.houseType
        newInput.houseArea = originalInput.houseArea
        newInput.housePricePerSqm = (remainingAfterPrepayment + originalInput.downPayment) / originalInput.houseArea
        newInput.downPaymentRatio = originalInput.downPaymentRatio
        newInput.loanTerm = originalInput.loanTerm
        newInput.repaymentMethod = originalInput.repaymentMethod
        newInput.housingFundEnabled = originalInput.housingFundEnabled
        newInput.housingFundBalance = originalInput.housingFundBalance
        newInput.housingFundMonthly = originalInput.housingFundMonthly
        newInput.spouseHousingFund = originalInput.spouseHousingFund
        newInput.spouseHousingFundBalance = originalInput.spouseHousingFundBalance
        newInput.lprBase = originalInput.lprBase
        newInput.floatingRatio = originalInput.floatingRatio
        let newSchedule = schedule(input: newInput)
        let newMonths = newSchedule.count

        let originalTotalInterest = originalSchedule.reduce(0) { $0 + $1.totalInterest }
        let newTotalInterest = newSchedule.reduce(0) { $0 + $1.totalInterest }

        let interestSaved = originalTotalInterest - newTotalInterest
        let monthsSaved = months - newMonths

        return PrepaymentScenario(
            prepaymentAmount: prepaymentAmount,
            monthsSaved: monthsSaved,
            interestSaved: interestSaved,
            newMonthlyPayment: newSchedule.first?.totalPayment,
            newLoanTermMonths: newMonths,
            remainingPrincipal: remainingAfterPrepayment,
            label: prepaymentAmount >= 50000 ? "大额还款" : "小额还款"
        )
    }

    /// Find optimal prepayment amounts (5万, 10万, 20万)
    static func findOptimalPrepaymentScenarios(originalInput: LoanInputV2) -> [PrepaymentScenario] {
        let amounts: [Double] = [50000, 100000, 200000]
        return amounts.compactMap { amount in
            let scenario = calculatePrepayment(originalInput: originalInput, prepaymentAmount: amount, reduceTerm: true)
            if scenario.interestSaved > 0 {
                return scenario
            }
            return nil
        }
    }

    // MARK: - DSR (Debt Service Ratio) Affordability

    /// Monthly income estimate for DSR calculation
    static func estimateMonthlyIncome(loanAmount: Double, loanTermYears: Int) -> Double {
        // Reverse-engineer income: if DSR target is 30%, find income that gives DSR=30%
        // monthly payment * 30% = income -> income = monthly payment / 0.3
        let months = Double(loanTermYears * 12)
        let rate = 0.035 / 12
        let power = pow(1 + rate, months)
        let monthlyPayment = loanAmount * rate * power / (power - 1)
        return monthlyPayment / 0.30
    }

    /// Calculate DSR given income
    static func calculateDSR(monthlyPayment: Double, monthlyIncome: Double) -> Double {
        guard monthlyIncome > 0 else { return 1.0 }
        return monthlyPayment / monthlyIncome
    }

    /// DSR rating
    enum DSRRating: String {
        case excellent = "极优"
        case good = "良好"
        case moderate = "适中"
        case caution = "偏高"
        case danger = "过高"

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "mint"
            case .moderate: return "yellow"
            case .caution: return "orange"
            case .danger: return "red"
            }
        }

        static func from(dsr: Double) -> DSRRating {
            if dsr < 0.20 { return .excellent }
            if dsr < 0.30 { return .good }
            if dsr < 0.40 { return .moderate }
            if dsr < 0.50 { return .caution }
            return .danger
        }

        var advice: String {
            switch self {
            case .excellent: return "还款压力极小，财务状况非常健康"
            case .good: return "还款压力适中，财务状况良好"
            case .moderate: return "还款压力中等，建议预留流动资金"
            case .caution: return "还款压力偏高，需谨慎规划其他开支"
            case .danger: return "还款压力过大，建议降低贷款额度"
            }
        }
    }

    /// DSR assessment result
    struct DSRAssessment {
        let dsr: Double                    // 负债率 (0-1)
        let rating: DSRRating
        let suggestedMaxLoan: Double       // 建议最高贷款
        let suggestedMaxMonthlyPayment: Double
        let monthlyIncome: Double
        let monthlyPayment: Double
    }

    static func assessDSR(monthlyIncome: Double, monthlyPayment: Double) -> DSRAssessment {
        let dsr = calculateDSR(monthlyPayment: monthlyPayment, monthlyIncome: monthlyIncome)
        let rating = DSRRating.from(dsr: dsr)
        let suggestedMaxMonthly = monthlyIncome * 0.40
        // Reverse: suggestedMaxMonthly / monthlyRate simulation
        let rate = 0.035 / 12
        let months = 360.0
        let power = pow(1 + rate, months)
        let suggestedMaxLoan = suggestedMaxMonthly * (power - 1) / (rate * power)

        return DSRAssessment(
            dsr: dsr,
            rating: rating,
            suggestedMaxLoan: suggestedMaxLoan,
            suggestedMaxMonthlyPayment: suggestedMaxMonthly,
            monthlyIncome: monthlyIncome,
            monthlyPayment: monthlyPayment
        )
    }

    // MARK: - Repayment Method Advisor

    enum RepaymentAdvice: String {
        case equalPayment = "等额本息"
        case equalPrincipal = "等额本金"
        case interestFirst = "先息后本"

        var reason: String {
            switch self {
            case .equalPayment:
                return "月供固定，便于家庭预算管理，长期来看总利息稍高但压力均匀"
            case .equalPrincipal:
                return "前期月供高但总利息最少，适合收入较高且追求省息的借款人"
            case .interestFirst:
                return "前期只还利息、本金不变，适合短期周转或投资回报预期高的群体"
            }
        }
    }

    static func suggestRepaymentMethod(input: LoanInputV2) -> RepaymentAdvice {
        let loanAmount = input.loanAmount
        let months = input.loanTerm * 12

        // Equal principal saves most interest
        if input.loanTerm <= 10 {
            return .equalPrincipal
        }

        // For very large loans, equal payment reduces early burden
        if loanAmount > 3000000 {
            return .equalPayment
        }

        // Short-term: interest first viable
        if input.loanTerm <= 5 {
            return .interestFirst
        }

        // Default to equal payment for stability
        return .equalPayment
    }

    // MARK: - Auto-Generated Comparison Scenarios

    struct ComparisonScenario: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let monthlyPayment: Double
        let totalInterest: Double
        let totalPayment: Double
        let tag: String   // "推荐" "省息" "低月供"
        let input: LoanInputV2
        let result: LoanResultV2
    }

    static func generateComparisonScenarios(input: LoanInputV2) -> [ComparisonScenario] {
        var scenarios: [ComparisonScenario] = []

        // Scenario 1: Current plan (already calculated)
        let currentResult = calculate(input: input)
        scenarios.append(ComparisonScenario(
            title: "当前方案",
            description: "基于当前参数的计算结果",
            icon: "house.fill",
            monthlyPayment: currentResult.totalMonthlyPayment,
            totalInterest: currentResult.totalInterest,
            totalPayment: currentResult.totalPayment,
            tag: "当前",
            input: input,
            result: currentResult
        ))

        // Scenario 2: Shorter term (save interest)
        var shortInput = input
        shortInput.loanTerm = max(15, input.loanTerm - 5)
        let shortResult = calculate(input: shortInput)
        let interestSaved = currentResult.totalInterest - shortResult.totalInterest
        scenarios.append(ComparisonScenario(
            title: "缩短期限",
            description: "\(shortInput.loanTerm)年 vs \(input.loanTerm)年，节省利息 \(Formatters.currency(interestSaved))",
            icon: "clock.fill",
            monthlyPayment: shortResult.totalMonthlyPayment,
            totalInterest: shortResult.totalInterest,
            totalPayment: shortResult.totalPayment,
            tag: "省息",
            input: shortInput,
            result: shortResult
        ))

        // Scenario 3: More down payment (lower monthly)
        var moreDownInput = input
        moreDownInput.downPaymentRatio = min(0.40, input.downPaymentRatio + 0.10)
        let moreDownResult = calculate(input: moreDownInput)
        scenarios.append(ComparisonScenario(
            title: "提高首付",
            description: "首付\(Int(moreDownInput.downPaymentRatio * 100))%，降低月供压力",
            icon: "banknote.fill",
            monthlyPayment: moreDownResult.totalMonthlyPayment,
            totalInterest: moreDownResult.totalInterest,
            totalPayment: moreDownResult.totalPayment,
            tag: "低月供",
            input: moreDownInput,
            result: moreDownResult
        ))

        return scenarios
    }
}
