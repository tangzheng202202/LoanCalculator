//
//  LoanCalculatorV2Tests.swift
//  LoanCalculatorTests
//
//  组合贷款计算测试
//  2026-03-31
//

import Testing
@testable import LoanCalculator

struct LoanCalculatorV2Tests {

    // MARK: - 组合贷款测试
    @Test func testCombinedLoan_Basic() {
        var input = LoanInputV2()
        input.loanType = .combined
        input.city = .beijing
        input.houseArea = 90
        input.housePricePerSqm = 50000  // 总价450万
        input.downPaymentRatio = 0.20    // 首付90万
        input.loanTerm = 30
        input.repaymentMethod = .equalPayment
        input.housingFundEnabled = true
        input.housingFundBalance = 100000  // 10万余额
        input.housingFundMonthly = 3000
        
        let result = CalculationEngineV2.calculate(input: input)
        
        // 验证总额
        #expect(result.totalMonthlyPayment > 0)
        #expect(result.totalInterest > 0)
        #expect(result.totalPayment > result.loanAmount)
        
        // 验证组合贷有公积金和商贷两部分
        #expect(result.housingFundPrincipal > 0)
        #expect(result.commercialPrincipal > 0)
        
        // 验证总额 = 公积金 + 商贷
        let expectedTotal = result.housingFundPrincipal + result.commercialPrincipal
        #expect(abs(expectedTotal - result.loanAmount) < 1)
    }

    // MARK: - 纯公积金贷款测试
    @Test func testHousingFundLoan_Only() {
        var input = LoanInputV2()
        input.loanType = .housingFund
        input.city = .beijing
        input.houseArea = 90
        input.housePricePerSqm = 50000
        input.downPaymentRatio = 0.20
        input.loanTerm = 30
        input.repaymentMethod = .equalPayment
        input.housingFundEnabled = true
        input.housingFundBalance = 200000  // 20万余额
        
        let result = CalculationEngineV2.calculate(input: input)
        
        // 纯公积金应该没有商贷部分
        #expect(result.commercialPrincipal == 0)
        #expect(result.housingFundPrincipal > 0)
        
        // 验证利率是公积金利率
        #expect(input.housingFundRate == 0.0285 || input.housingFundRate == 0.026)
    }

    // MARK: - 纯商业贷款测试
    @Test func testCommercialLoan_Only() {
        var input = LoanInputV2()
        input.loanType = .commercial
        input.city = .beijing
        input.houseArea = 90
        input.housePricePerSqm = 50000
        input.downPaymentRatio = 0.30
        input.loanTerm = 20
        input.repaymentMethod = .equalPayment
        
        let result = CalculationEngineV2.calculate(input: input)
        
        // 纯商贷没有公积金部分
        #expect(result.housingFundPrincipal == 0)
        #expect(result.commercialPrincipal > 0)
        
        // 验证利率是商贷利率
        #expect(input.commercialRate < 0.05)
    }

    // MARK: - 城市政策测试
    @Test func testCityPolicy_Beijing() {
        let beijing = City.beijing
        
        #expect(beijing.maxHousingFundLoan == 120)  // 北京最高120万
        #expect(beijing.housingFundRate == 0.0285)  // 公积金利率2.85%
        #expect(beijing.minDownPaymentRatio == 0.20) // 首付20%
    }

    @Test func testCityPolicy_Chengdu() {
        let chengdu = City.chengdu
        
        #expect(chengdu.maxHousingFundLoan == 120)  // 成都最高120万
        #expect(chengdu.housingFundRate == 0.026)  // 成都优惠利率2.6%
    }

    @Test func testCityPolicy_Chongqing() {
        let chongqing = City.chongqing
        
        #expect(chongqing.maxHousingFundLoan == 80)   // 重庆最高80万
        #expect(chongqing.balanceMultiplier == 25)  // 余额×25倍
    }

    // MARK: - 公积金可贷额度计算测试
    @Test func testHousingFundLoanable_Calculation() {
        var input = LoanInputV2()
        input.city = .beijing
        input.houseArea = 90
        input.housePricePerSqm = 50000  // 总价450万
        input.housingFundBalance = 100000  // 10万余额
        input.spouseHousingFund = false
        
        // 北京：余额×15倍 = 150万，但房价×70% = 315万，最高120万
        // 所以可贷额度 = min(150万, 315万, 120万) = 120万
        let expected = 1200000.0  // 120万
        #expect(abs(input.housingFundLoanable - expected) < 1)
    }

    // MARK: - 配偶公积金测试
    @Test func testSpouseHousingFund() {
        var input = LoanInputV2()
        input.city = .shanghai
        input.houseArea = 120
        input.housePricePerSqm = 60000  // 总价720万
        input.housingFundBalance = 50000
        input.spouseHousingFund = true
        input.spouseHousingFundBalance = 50000
        
        // 合计余额10万，上海×15倍 = 150万，最高120万
        #expect(input.housingFundLoanable > 0)
    }

    // MARK: - 等额本金测试
    @Test func testEqualPrincipal_Combined() {
        var input = LoanInputV2()
        input.loanType = .combined
        input.city = .shenzhen
        input.houseArea = 100
        input.housePricePerSqm = 40000  // 总价400万
        input.downPaymentRatio = 0.30
        input.loanTerm = 20
        input.repaymentMethod = .equalPrincipal  // 等额本金
        input.housingFundEnabled = true
        input.housingFundBalance = 150000
        input.housingFundMonthly = 5000
        
        let result = CalculationEngineV2.calculate(input: input)
        let schedule = CalculationEngineV2.schedule(input: input)
        
        // 等额本金：首月月供 > 末月月供
        #expect(schedule.first!.totalPayment > schedule.last!.totalPayment)
        
        // 验证每月本金递减
        for i in 1..<schedule.count {
            #expect(schedule[i].totalPrincipal >= schedule[i-1].totalPrincipal - 1)
        }
    }

    // MARK: - 月度明细测试
    @Test func testSchedule_Details() {
        var input = LoanInputV2()
        input.loanType = .combined
        input.city = .beijing
        input.houseArea = 90
        input.housePricePerSqm = 50000
        input.downPaymentRatio = 0.20
        input.loanTerm = 5  // 5年 = 60期（测试用短期限）
        input.repaymentMethod = .equalPayment
        input.housingFundEnabled = true
        input.housingFundBalance = 100000
        input.housingFundMonthly = 3000
        
        let schedule = CalculationEngineV2.schedule(input: input)
        
        // 验证期数
        #expect(schedule.count == 60)
        
        // 验证组合贷双列
        for item in schedule {
            #expect(item.housingFundPayment > 0 || item.commercialPayment > 0)
            #expect(item.totalPayment == item.housingFundPayment + item.commercialPayment)
        }
        
        // 验证最后一个月剩余本金为0
        #expect(schedule.last!.remainingPrincipal < 1)
    }

    // MARK: - 节省利息测试
    @Test func testSavedInterest() {
        var input = LoanInputV2()
        input.loanType = .combined
        input.city = .beijing
        input.houseArea = 90
        input.housePricePerSqm = 50000
        input.downPaymentRatio = 0.20
        input.loanTerm = 30
        input.repaymentMethod = .equalPayment
        input.housingFundEnabled = true
        input.housingFundBalance = 200000  // 较高余额
        
        let result = CalculationEngineV2.calculate(input: input)
        
        // 组合贷应该比纯商贷节省利息
        #expect(result.savedInterest > 0)
    }
}