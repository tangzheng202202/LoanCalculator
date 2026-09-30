//
//  LoanCalculatorV2Tests.swift
//  LoanCalculatorTests
//
//  组合贷款计算测试
//  2026-03-31
//

import Foundation
import Testing
@testable import LoanCalculator

struct LoanCalculatorV2Tests {

    @Test func testCSVExportUsesActualV2PrincipalAndSchedule() throws {
        let input = LoanInputV2()
        input.city = .shanghai
        input.loanType = .housingFund
        input.housingFundEnabled = true
        input.housingFundBalance = 1000
        input.loanTerm = 1
        let result = CalculationEngineV2.calculate(input: input)

        let url = try #require(ExportManager.exportToCSV(input: input, result: result))
        defer { try? FileManager.default.removeItem(at: url) }
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
        let firstMonth = try #require(CalculationEngineV2.schedule(input: input).first)

        #expect(result.loanAmount == 15000)
        #expect(url.lastPathComponent.contains("15000元"))
        #expect(lines.count == 13)
        #expect(lines[0] == "月份,月供,本金,利息,剩余本金")
        #expect(lines[1] == Substring(String(format: "1,%.2f,%.2f,%.2f,%.2f",
                                              firstMonth.totalPayment,
                                              firstMonth.totalPrincipal,
                                              firstMonth.totalInterest,
                                              firstMonth.remainingPrincipal)))
    }

    @Test func testPDFExportCreatesV2Document() throws {
        let input = LoanInputV2()
        input.city = .shanghai
        input.loanType = .combined
        input.housingFundEnabled = true
        input.housingFundBalance = 1000
        input.loanTerm = 1
        let result = CalculationEngineV2.calculate(input: input)

        let url = try #require(ExportManager.exportToPDF(input: input, result: result))
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)

        #expect(url.lastPathComponent.contains("\(Int(result.loanAmount))元"))
        #expect(data.count > 100)
        #expect(data.prefix(4) == Data("%PDF".utf8))
    }

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
        input.beijingPlannedHousingFundPrincipal = 1_000_000
        
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
        input.houseArea = 30
        input.housePricePerSqm = 50000
        input.downPaymentRatio = 0.20
        input.loanTerm = 30
        input.repaymentMethod = .equalPayment
        input.housingFundEnabled = true
        input.housingFundBalance = 200000  // 20万余额
        
        #expect(input.validate())
        let result = CalculationEngineV2.calculate(input: input)
        
        // 纯公积金应该没有商贷部分
        #expect(result.commercialPrincipal == 0)
        #expect(result.housingFundPrincipal == input.loanAmount)
        #expect(result.loanAmount == result.housingFundPrincipal)
        
        // 验证利率是公积金利率
        #expect(input.housingFundRate == 0.026)
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
        #expect(beijing.housingFundRate == 0.026)  // 5年以上首套利率2.6%
        #expect(beijing.minDownPaymentRatio == 0.20) // 首付20%
        #expect(beijing.minDownPaymentRatio(loanType: .commercial, houseType: .first) == 0.15)
        #expect(beijing.minDownPaymentRatio(loanType: .commercial, houseType: .second) == 0.20)
        #expect(beijing.minDownPaymentRatio(loanType: .housingFund, houseType: .first) == 0.20)
        #expect(beijing.minDownPaymentRatio(loanType: .combined, houseType: .second) == 0.25)
        #expect(beijing.housingFundRate(houseType: .first, loanTerm: 5) == 0.021)
        #expect(beijing.housingFundRate(houseType: .second, loanTerm: 5) == 0.02525)
        #expect(beijing.housingFundRate(houseType: .second, loanTerm: 30) == 0.03075)
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
    @Test func testBeijingBasicHousingFundCapUsesContributionMonths() {
        let input = LoanInputV2()
        input.city = .beijing
        input.housingFundEnabled = true
        input.housingFundBalance = 100_000
        #expect(input.beijingBasicHousingFundCap == nil)
        #expect(input.housingFundLoanable == 0) // 余额接口在北京失效
        input.housingFundContributionMonths = 13
        #expect(input.beijingBasicHousingFundCap == 400_000) // 不满整年进一整年
        input.housingFundContributionMonths = 120
        #expect(input.beijingBasicHousingFundCap == 1_200_000)
        input.houseType = .second
        #expect(input.beijingBasicHousingFundCap == 1_000_000)
        input.spouseHousingFund = true
        #expect(input.beijingBasicHousingFundCap == nil)
        input.spouseHousingFundContributionMonths = 25
        #expect(input.beijingBasicHousingFundCap == 2_000_000)
        input.houseType = .first
        #expect(input.beijingBasicHousingFundCap == 2_400_000)
    }

    // MARK: - 配偶公积金测试
    @Test func testSpouseHousingFund() {
        var input = LoanInputV2()
        input.city = .shanghai
        input.houseArea = 120
        input.housePricePerSqm = 60000  // 总价720万
        input.housingFundBalance = 50000
        input.housingFundEnabled = true
        input.spouseHousingFund = true
        input.spouseHousingFundBalance = 50000
        
        // 合计余额10万，上海×15倍 = 150万，最高120万
        #expect(abs(input.housingFundLoanable - 1200000) < 1)
    }

    @Test func testBeijingAllocationUsesPlannedPrincipalNotBalance() {
        let city = City.beijing
        #expect(city.calculateHousingFundLoanable(balance: 1000, housePrice: 4500000, houseType: .first) == 0)

        let input = LoanInputV2()
        input.loanType = .combined
        input.city = city
        input.housingFundEnabled = true
        input.housingFundBalance = 1000
        input.spouseHousingFundBalance = 1000
        input.beijingPlannedHousingFundPrincipal = 800_000

        // 账户余额及配偶开关均不改变用户填写的方案本金。
        let withoutSpouse = CalculationEngineV2.calculate(input: input)
        #expect(withoutSpouse.housingFundPrincipal == 800_000)

        input.spouseHousingFund = true
        let withSpouse = CalculationEngineV2.calculate(input: input)
        #expect(withSpouse.housingFundPrincipal == 800_000)
        #expect(withSpouse.commercialPrincipal == input.loanAmount - 800_000)
        #expect(withSpouse.housingFundPrincipal + withSpouse.commercialPrincipal == input.loanAmount)
        #expect(input.housingFundLoanable == 0)
    }

    @Test func testHousingFundDisabledDoesNotAllocateLoan() {
        let input = LoanInputV2()
        input.loanType = .combined
        input.housingFundBalance = 50000
        input.housingFundEnabled = false

        #expect(input.housingFundLoanable == 0)
        #expect(input.validate())
        let combined = CalculationEngineV2.calculate(input: input)
        #expect(combined.housingFundPrincipal == 0)
        #expect(combined.commercialPrincipal == input.loanAmount)
        #expect(combined.loanAmount == input.loanAmount)

        input.loanType = .housingFund
        #expect(!input.validate())
        #expect(input.validationErrors.contains("公积金贷款须启用公积金"))
        let fundOnly = CalculationEngineV2.calculate(input: input)
        #expect(fundOnly.housingFundPrincipal == 0)
        #expect(fundOnly.commercialPrincipal == 0)
        #expect(fundOnly.loanAmount == 0)
    }

    @Test func testNegativeSpouseBalanceIsRejectedAndCannotAllocateNegativePrincipal() {
        let input = LoanInputV2()
        input.city = .shanghai
        input.loanType = .combined
        input.housingFundEnabled = true
        input.housingFundBalance = 1000
        input.spouseHousingFund = true
        input.spouseHousingFundBalance = -2000

        #expect(!input.validate())
        #expect(input.validationErrors.contains("配偶公积金账户余额不能为负"))
        #expect(input.housingFundLoanable == 0)
        let result = CalculationEngineV2.calculate(input: input)
        #expect(result.housingFundPrincipal == 0)
        #expect(result.commercialPrincipal == input.loanAmount)

        input.spouseHousingFund = false
        #expect(input.validate())
        #expect(input.housingFundLoanable == 15000)
    }

    @Test func testBeijingBasicCapDoesNotDecideApproval() {
        let input = LoanInputV2()
        input.loanType = .housingFund
        input.housingFundEnabled = true
        input.housingFundBalance = 1000
        input.housingFundContributionMonths = 1

        #expect(input.loanAmount == 3600000)
        #expect(input.beijingBasicHousingFundCap == 200_000)
        #expect(input.validate()) // 基本上限不含上浮及审批，不据此拒绝方案测算。

        // 结果按假设的全额公积金方案本金测算，不表示申请可获批。
        let result = CalculationEngineV2.calculate(input: input)
        let schedule = CalculationEngineV2.schedule(input: input)
        #expect(result.housingFundPrincipal == input.loanAmount)
        #expect(result.commercialPrincipal == 0)
        #expect(result.loanAmount == input.loanAmount)
        #expect(abs(result.totalPayment - result.totalInterest - result.loanAmount) < 0.01)
        #expect(abs(schedule.reduce(0) { $0 + $1.totalPrincipal } - result.loanAmount) < 0.01)
        #expect(schedule.last?.remainingPrincipal == 0)

        let allCommercial = CalculationEngineV2.calcLoan(
            principal: result.loanAmount,
            annualRate: input.commercialRate,
            months: input.loanTerm * 12,
            method: input.repaymentMethod
        )
        #expect(abs(result.savedInterestIfAllCommercial - allCommercial.totalInterest) < 0.01)
        #expect(abs(result.savedInterest - (allCommercial.totalInterest - result.totalInterest)) < 0.01)

        let historyItem = HistoryManager.makeItem(input: input, result: result)
        #expect(historyItem.loanAmount == result.loanAmount)
        #expect(historyItem.totalPayment == result.totalPayment)
    }

    @Test func testBeijingScenarioPrincipalAndDownPaymentValidation() {
        let input = LoanInputV2()
        input.city = .beijing
        input.loanType = .commercial
        input.downPaymentRatio = 0.15
        #expect(input.validate())
        input.loanType = .combined
        #expect(!input.validate())
        input.downPaymentRatio = 0.20
        input.housingFundEnabled = true
        input.beijingPlannedHousingFundPrincipal = input.loanAmount + 1
        #expect(!input.validate())
        input.beijingPlannedHousingFundPrincipal = 600_000
        #expect(input.validate())
        #expect(input.autoCalculateLoanAmounts().housingFund == 600_000)
        input.housingFundBalance = 0
        #expect(input.autoCalculateLoanAmounts().housingFund == 600_000)
    }

    @Test func testEnteredCommercialBPAffectsPayment() {
        let input = LoanInputV2()
        input.loanType = .commercial
        input.city = .beijing
        input.floatingRatio = -0.005
        let lowerRatePayment = CalculationEngineV2.calculate(input: input).totalMonthlyPayment
        input.floatingRatio = 0.005
        #expect(input.commercialRate == 0.04)
        #expect(CalculationEngineV2.calculate(input: input).totalMonthlyPayment > lowerRatePayment)
        input.floatingRatio = -.infinity
        #expect(!input.validate())
    }

    @Test func testBeijingScenarioCSVMatchesCalculatedSchedule() throws {
        let input = LoanInputV2()
        input.city = .beijing
        input.loanType = .combined
        input.housingFundEnabled = true
        input.beijingPlannedHousingFundPrincipal = 700_000
        input.housingFundBalance = 0
        input.loanTerm = 1

        let result = CalculationEngineV2.calculate(input: input)
        let firstMonth = try #require(CalculationEngineV2.schedule(input: input).first)
        let url = try #require(ExportManager.exportToCSV(input: input, result: result))
        defer { try? FileManager.default.removeItem(at: url) }
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")

        #expect(result.housingFundPrincipal == 700_000)
        #expect(result.commercialPrincipal == input.loanAmount - 700_000)
        #expect(url.lastPathComponent.hasPrefix("方案测算明细_"))
        #expect(lines.count == 13)
        #expect(lines[1] == Substring(String(format: "1,%.2f,%.2f,%.2f,%.2f",
                                              firstMonth.totalPayment,
                                              firstMonth.totalPrincipal,
                                              firstMonth.totalInterest,
                                              firstMonth.remainingPrincipal)))
    }

    @Test func testLegacyHistoryRecordStillDecodes() throws {
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000001","createdAt":0,
         "loanType":"组合贷款","city":"北京","houseType":"首套房",
         "houseArea":90,"housePricePerSqm":50000,"downPaymentPercent":20,
         "loanTerm":30,"repaymentMethod":"等额本息","loanAmount":3600000,
         "monthlyPayment":15000,"totalInterest":1800000,"totalPayment":5400000}
        """
        let oldItem = try JSONDecoder().decode(LoanHistoryItem.self, from: Data(legacyJSON.utf8))
        #expect(oldItem.loanAmount == 3_600_000)
        let restored = HistoryManager.shared.restoreToInput(oldItem)
        #expect(restored.city == .beijing)
        #expect(restored.loanType == .combined)
        #expect(restored.downPaymentRatio == 0.20)
    }

    @Test func testZeroRateEqualPayment() {
        let payment = CalculationEngineV2.calcLoan(principal: 120000, annualRate: 0, months: 12, method: .equalPayment)
        #expect(payment.monthlyPayment == 10000)
        #expect(payment.totalPayment == 120000)
        #expect(payment.totalInterest == 0)

        let schedule = CalculationEngineV2.generateSchedule(principal: 120000, monthlyRate: 0, months: 12, method: .equalPayment)
        #expect(schedule.count == 12)
        #expect(schedule.allSatisfy { $0.payment == 10000 && $0.interest == 0 })
        #expect(schedule.last?.remaining == 0)
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
        input.beijingPlannedHousingFundPrincipal = 1_000_000
        
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
        input.beijingPlannedHousingFundPrincipal = 1_000_000
        
        let result = CalculationEngineV2.calculate(input: input)
        
        // 组合贷应该比纯商贷节省利息
        #expect(result.savedInterest > 0)
    }
}
