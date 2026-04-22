//
//  LoanResultV2.swift
//  LoanCalculator
//
//  扩展的贷款结果模型（支持组合贷款）
//

import Foundation

/// 组合贷款结果
struct LoanResultV2 {
    // MARK: - 总体结果
    var totalMonthlyPayment: Double     // 合计月供
    var totalPayment: Double          // 还款总额
    var totalInterest: Double         // 利息总额
    
    // MARK: - 公积金部分
    var housingFundMonthlyPayment: Double  // 公积金月供
    var housingFundTotalInterest: Double    // 公积金利息
    var housingFundTotalPayment: Double    // 公积金还款总额
    var housingFundPrincipal: Double       // 公积金贷款本金
    
    // MARK: - 商业贷款部分
    var commercialMonthlyPayment: Double  // 商贷月供
    var commercialTotalInterest: Double    // 商贷利息
    var commercialTotalPayment: Double     // 商贷还款总额
    var commercialPrincipal: Double       // 商贷本金
    
    // MARK: - 统计信息
    var loanTerm: Int                     // 贷款期限
    var loanAmount: Double               // 贷款总额
    var loanType: LoanType               // 贷款类型
    var city: City                       // 城市
    
    // MARK: - 节省利息
    /// 商业贷款利率（用于计算纯商贷对比）
    var commercialRate: Double = 0.035
    
    /// 如果全部用商业贷款需要的总利息
    var savedInterestIfAllCommercial: Double {
        let rate = commercialRate / 12
        let months = Double(loanTerm * 12)
        let power = pow(1 + rate, months)
        let monthly = loanAmount * rate * power / (power - 1)
        return monthly * months - loanAmount
    }
    
    /// 组合贷比纯商贷节省的利息
    var savedInterest: Double {
        savedInterestIfAllCommercial - totalInterest
    }
}

/// 月度还款明细（组合贷）
struct MonthlyScheduleItemV2: Identifiable {
    var id: Int { month }
    var month: Int
    
    // 合计
    var totalPayment: Double
    var totalPrincipal: Double
    var totalInterest: Double
    var remainingPrincipal: Double
    
    // 公积金部分
    var housingFundPayment: Double
    var housingFundPrincipal: Double
    var housingFundInterest: Double
    
    // 商业贷款部分
    var commercialPayment: Double
    var commercialPrincipal: Double
    var commercialInterest: Double
}
