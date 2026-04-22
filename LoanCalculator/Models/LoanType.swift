//
//  LoanType.swift
//  LoanCalculator
//
//  贷款类型枚举 + 城市精细政策
//

import Foundation

/// 贷款类型
enum LoanType: String, CaseIterable, Identifiable {
    case commercial = "商业贷款"
    case housingFund = "公积金贷款"
    case combined = "组合贷款"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .commercial: return "商业贷款"
        case .housingFund: return "公积金贷款"
        case .combined: return "组合贷款（公积金+商业）"
        }
    }
}

/// 房屋类型
enum HouseType: String, CaseIterable, Identifiable {
    case first = "首套房"
    case second = "二套房"
    
    var id: String { rawValue }
}

/// 城市（用于公积金政策）
enum City: String, CaseIterable, Identifiable {
    case beijing = "北京"
    case shanghai = "上海"
    case guangzhou = "广州"
    case shenzhen = "深圳"
    case chengdu = "成都"
    case chongqing = "重庆"
    
    var id: String { rawValue }
    
    // MARK: - 首套房政策
    
    /// 公积金贷款最高额度（万元）- 首套房
    var maxHousingFundLoanFirst: Double {
        switch self {
        case .beijing: return 120     // 北京首套120万
        case .shanghai: return 120    // 上海首套120万（有补充公积金可达110万）
        case .guangzhou: return 120    // 广州首套100-120万
        case .shenzhen: return 120    // 深圳首套90-120万
        case .chengdu: return 120     // 成都首套80-120万（2026年上浮）
        case .chongqing: return 80    // 重庆首套80万
        }
    }
    
    /// 公积金贷款最高额度（万元）- 二套房
    var maxHousingFundLoanSecond: Double {
        switch self {
        case .beijing: return 100     // 北京二套100万
        case .shanghai: return 100    // 上海二套100万
        case .guangzhou: return 100    // 广州二套100万
        case .shenzhen: return 90     // 深圳二套90万
        case .chengdu: return 80      // 成都二套80万
        case .chongqing: return 80    // 重庆二套80万
        }
    }
    
    /// 公积金贷款利率（5年以上）
    var housingFundRateFirst: Double {
        switch self {
        case .chengdu, .chongqing: return 0.026  // 成都重庆2026年优惠利率2.6%
        default: return 0.0285 // 全国统一2.85%
        }
    }
    
    var housingFundRateSecond: Double {
        switch self {
        case .chengdu, .chongqing: return 0.03075  // 成都重庆二套3.075%
        default: return 0.03075 // 全国统一3.075%
        }
    }
    
    /// 公积金贷款利率（5年以下）
    var housingFundRateShort: Double {
        switch self {
        case .chengdu, .chongqing: return 0.021  // 成都重庆2.1%
        default: return 0.021  // 全国统一2.1%
        }
    }
    
    /// 首付比例要求（首套）
    var minDownPaymentRatioFirst: Double {
        switch self {
        case .beijing: return 0.20  // 20%
        case .shanghai: return 0.20  // 20%（普通住宅）/30%（非普通）
        case .guangzhou: return 0.20 // 20%
        case .shenzhen: return 0.20  // 20%
        case .chengdu: return 0.20  // 20%
        case .chongqing: return 0.20 // 20%
        }
    }
    
    /// 首付比例要求（二套）
    var minDownPaymentRatioSecond: Double {
        switch self {
        case .beijing: return 0.25  // 25%
        case .shanghai: return 0.50  // 50%（普通）/70%（非普通）
        case .guangzhou: return 0.30 // 30%
        case .shenzhen: return 0.30  // 30%
        case .chengdu: return 0.30  // 30%
        case .chongqing: return 0.30 // 30%
        }
    }
    
    /// 最高贷款成数（首套）
    var maxLoanRatioFirst: Double {
        switch self {
        case .beijing: return 0.80  // 80%
        case .shanghai: return 0.80  // 80%（普通）/70%（非普通）
        case .guangzhou: return 0.80 // 80%
        case .shenzhen: return 0.80  // 80%
        case .chengdu: return 0.80  // 80%
        case .chongqing: return 0.80 // 80%
        }
    }
    
    /// 最高贷款成数（二套）
    var maxLoanRatioSecond: Double {
        switch self {
        case .beijing: return 0.75  // 75%
        case .shanghai: return 0.50  // 50%（普通）/30%（非普通）
        case .guangzhou: return 0.70 // 70%
        case .shenzhen: return 0.70  // 70%
        case .chengdu: return 0.70  // 70%
        case .chongqing: return 0.70 // 70%
        }
    }
    
    /// 额度计算倍数
    var balanceMultiplier: Double {
        switch self {
        case .beijing: return 15   // 每缴1年=15万
        case .shanghai: return 15  // 余额×倍数
        case .guangzhou: return 8   // 余额×8+月缴×系数
        case .shenzhen: return 14  // 存贷挂钩
        case .chengdu: return 25    // 余额×25倍
        case .chongqing: return 25 // 余额×25倍
        }
    }
    
    /// 最低缴存月数要求
    var minContributionMonths: Int {
        switch self {
        case .beijing: return 6   // 北京6个月
        case .shanghai: return 6  // 上海6个月
        case .guangzhou: return 6  // 广州6个月
        case .shenzhen: return 6  // 深圳6个月
        case .chengdu: return 6   // 成都6个月
        case .chongqing: return 6 // 重庆6个月
        }
    }
    
    /// 商贷基准利率（5年期LPR）
    var lprBase: Double {
        0.035  // 2026年3月 5年期LPR = 3.5%
    }
    
    /// 商贷首套浮动（BP）
    var commercialFloatingFirst: Double {
        switch self {
        case .beijing: return -0.005  // -5BP = 3.45%
        case .shanghai: return -0.006  // -6BP = 3.44%
        case .guangzhou: return -0.005 // -5BP = 3.45%
        case .shenzhen: return -0.005  // -5BP = 3.45%
        case .chengdu: return -0.005   // -5BP = 3.45%
        case .chongqing: return -0.005 // -5BP = 3.45%
        }
    }
    
    /// 商贷二套浮动（BP）
    var commercialFloatingSecond: Double {
        switch self {
        case .beijing: return 0.005   // +5BP = 3.55%
        case .shanghai: return 0.006   // +6BP = 3.56%
        case .guangzhou: return 0.006  // +6BP = 3.56%
        case .shenzhen: return 0.006   // +6BP = 3.56%
        case .chengdu: return 0.006    // +6BP = 3.56%
        case .chongqing: return 0.006  // +6BP = 3.56%
        }
    }
    
    /// 计算公积金可贷额度
    func calculateHousingFundLoanable(balance: Double, spouseBalance: Double = 0, housePrice: Double, houseType: HouseType) -> Double {
        let totalBalance = balance + spouseBalance
        let maxByBalance = totalBalance * balanceMultiplier * 10000
        let maxByPrice = housePrice * (houseType == .first ? maxLoanRatioFirst : maxLoanRatioSecond)
        let maxByPolicy = houseType == .first ? maxHousingFundLoanFirst : maxHousingFundLoanSecond
        let maxPolicyAmount = maxByPolicy * 10000
        
        return min(maxByBalance, min(maxByPrice, maxPolicyAmount))
    }
    
    /// 计算商贷利率
    func calculateCommercialRate(houseType: HouseType) -> Double {
        let floating = houseType == .first ? commercialFloatingFirst : commercialFloatingSecond
        return lprBase + floating
    }
    
    /// 便捷属性（兼容旧代码）
    var maxHousingFundLoan: Double { maxHousingFundLoanFirst }
    var housingFundRate: Double { housingFundRateFirst }
    var minDownPaymentRatio: Double { minDownPaymentRatioFirst }
}
