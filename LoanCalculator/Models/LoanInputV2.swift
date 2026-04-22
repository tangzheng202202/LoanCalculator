//
//  LoanInputV2.swift
//  LoanCalculator
//
//  扩展的贷款输入模型（支持组合贷款）
//

import Foundation
import Combine

/// 扩展的贷款输入模型
class LoanInputV2: ObservableObject {
    // MARK: - 基本信息
    @Published var loanType: LoanType = .commercial
    @Published var city: City = .beijing
    @Published var houseType: HouseType = .first
    
    // MARK: - 房屋信息
    @Published var houseArea: Double = 90          // 房屋面积（平方米）
    @Published var housePricePerSqm: Double = 50000 // 单价（元/平方米）
    @Published var downPaymentRatio: Double = 0.20 // 首付比例
    
    // MARK: - 贷款参数
    @Published var loanTerm: Int = 30               // 贷款期限（年）
    @Published var repaymentMethod: RepaymentMethod = .equalPayment
    
    // MARK: - 公积金信息
    @Published var housingFundEnabled: Bool = false // 是否启用公积金
    @Published var housingFundBalance: Double = 50000 // 公积金账户余额（元）
    @Published var housingFundMonthly: Double = 3000   // 月缴存额（元）
    @Published var spouseHousingFund: Bool = false     // 配偶是否共用公积金
    @Published var spouseHousingFundBalance: Double = 0 // 配偶公积金余额
    
    // MARK: - 商业贷款信息
    @Published var lprBase: Double = 0.035         // LPR基准利率（5年期3.5%）
    @Published var floatingRatio: Double = -0.0060 // 浮动比例（-60BP = -0.6%）
    
    // MARK: - 验证错误信息
    @Published var validationErrors: [String] = []
    
    init() {}
    
    // MARK: - 计算属性（不存储）
    var totalHousePrice: Double {
        houseArea * housePricePerSqm
    }
    
    var downPayment: Double {
        totalHousePrice * downPaymentRatio
    }
    
    var loanAmount: Double {
        totalHousePrice - downPayment
    }
    
    var housingFundLoanable: Double {
        city.calculateHousingFundLoanable(
            balance: housingFundBalance,
            spouseBalance: spouseHousingFund ? spouseHousingFundBalance : 0,
            housePrice: totalHousePrice,
            houseType: houseType
        )
    }
    
    var housingFundRate: Double {
        houseType == .first ? city.housingFundRateFirst : city.housingFundRateSecond
    }
    
    var commercialRate: Double {
        city.calculateCommercialRate(houseType: houseType)
    }
    
    var minDownPaymentRatio: Double {
        houseType == .first ? city.minDownPaymentRatioFirst : city.minDownPaymentRatioSecond
    }
    
    // MARK: - 验证方法
    func validate() -> Bool {
        validationErrors.removeAll()
        
        // 房屋面积验证
        if houseArea < 1 || houseArea > 1000 {
            validationErrors.append("房屋面积应在1-1000平方米之间")
        }
        
        // 房屋单价验证
        if housePricePerSqm < 1000 || housePricePerSqm > 500000 {
            validationErrors.append("房屋单价应在1000-500000元/平方米之间")
        }
        
        // 首付比例验证
        let minDown = minDownPaymentRatio
        if downPaymentRatio < minDown || downPaymentRatio > 1.0 {
            validationErrors.append("首付比例应在\(Int(minDown * 100))%-100%之间")
        }
        
        // 贷款期限验证
        if loanTerm < 1 || loanTerm > 35 {
            validationErrors.append("贷款期限应在1-35年之间")
        }
        
        // 公积金余额验证
        if housingFundEnabled && housingFundBalance < 0 {
            validationErrors.append("公积金账户余额不能为负")
        }
        
        return validationErrors.isEmpty
    }
    
    // MARK: - 自动计算组合贷配比
    func autoCalculateLoanAmounts() -> (housingFund: Double, commercial: Double) {
        let totalLoan = loanAmount
        
        switch loanType {
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
}

/// 还款方式
enum RepaymentMethod: String, CaseIterable, Identifiable {
    case equalPayment = "等额本息"
    case equalPrincipal = "等额本金"
    case interestFirst = "先息后本"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .equalPayment:
            return "等额本息（月供固定，前期利息多）"
        case .equalPrincipal:
            return "等额本金（月供递减，前期压力大）"
        case .interestFirst:
            return "先息后本（每月还息，到期还本）"
        }
    }
}