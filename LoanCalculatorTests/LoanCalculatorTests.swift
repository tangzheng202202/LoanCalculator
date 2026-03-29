//
//  LoanCalculatorTests.swift
//  LoanCalculatorTests
//
//  贷款计算器 - 真实业务测试
//  Created by mac on 2026/3/29.
//

import Testing
@testable import LoanCalculator

struct LoanCalculatorTests {

    // MARK: - 等额本息测试（等额本息）
    // 贷款金额: 100万, 期限: 30年, 年利率: 4.2%, 月供约 ¥4,868
    @Test func testEqualPayment_Basic() {
        var input = LoanInput()
        input.loanAmount = 100
        input.loanTerm = 30
        input.annualRate = 4.2
        input.repaymentMethod = .equalPayment

        let result = CalculationEngine.calculate(input: input)

        #expect(result.monthlyPayment > 4800 && result.monthlyPayment < 5000)   // 月供约 4868
        #expect(result.totalPayment > result.monthlyPayment * 12 * 30 * 0.8)  // 总还款大于本金
        #expect(result.totalInterest > 0)                                        // 必须有利息
        #expect(result.totalInterest < result.totalPayment)                     // 利息小于总还款
    }

    // MARK: - 等额本金测试
    @Test func testEqualPrincipal_Basic() {
        var input = LoanInput()
        input.loanAmount = 100
        input.loanTerm = 20
        input.annualRate = 4.9
        input.repaymentMethod = .equalPrincipal

        let result = CalculationEngine.calculate(input: input)
        let schedule = CalculationEngine.schedule(input: input)

        // 首月月供应大于末月（等额本金特征）
        #expect(schedule.first?.payment ?? 0 > schedule.last?.payment ?? 0)
        // 每月本金相同
        #expect(schedule.allSatisfy { $0.principal == schedule[0].principal })
        // 总期数 = 20年 * 12 = 240期
        #expect(schedule.count == 240)
    }

    // MARK: - 先息后本测试
    @Test func testInterestFirst_Basic() {
        var input = LoanInput()
        input.loanAmount = 50
        input.loanTerm = 1
        input.annualRate = 5.0
        input.repaymentMethod = .interestFirst

        let result = CalculationEngine.calculate(input: input)
        let schedule = CalculationEngine.schedule(input: input)

        // 12期中每月只还利息，末月还本+息
        #expect(schedule.count == 12)
        #expect(schedule.dropLast().allSatisfy { $0.principal == 0 })     // 前11期不还本金
        #expect(schedule.last?.principal == input.amountInYuan)             // 末月本金 = 贷款总额
        #expect(result.totalInterest > 0)
    }

    // MARK: - 期数验证
    @Test func testScheduleLength() {
        var input = LoanInput()
        input.loanAmount = 100
        input.loanTerm = 10
        input.annualRate = 4.5
        input.repaymentMethod = .equalPayment

        let schedule = CalculationEngine.schedule(input: input)
        #expect(schedule.count == 120) // 10年 = 120期
    }

    // MARK: - 利率为0的特殊情况
    @Test func testZeroRate() {
        var input = LoanInput()
        input.loanAmount = 60
        input.loanTerm = 5
        input.annualRate = 0
        input.repaymentMethod = .equalPayment

        let result = CalculationEngine.calculate(input: input)
        let schedule = CalculationEngine.schedule(input: input)

        #expect(result.totalInterest == 0)                          // 零利率无利息
        #expect(result.monthlyPayment == 60_0000.0 / 60)           // 平摊本金
        #expect(schedule.allSatisfy { $0.interest == 0 })           // 每期利息为0
    }

    // MARK: - 计算结果一致性
    @Test func testConsistency() {
        var input = LoanInput()
        input.loanAmount = 200
        input.loanTerm = 15
        input.annualRate = 3.8
        input.repaymentMethod = .equalPayment

        let result = CalculationEngine.calculate(input: input)
        let schedule = CalculationEngine.schedule(input: input)

        // 月供一致性：所有期数月供应该相同（等额本息）
        let firstPayment = schedule.first?.payment ?? 0
        #expect(schedule.allSatisfy { abs($0.payment - firstPayment) < 0.01 })

        // 总还款 = 所有期数月供之和
        let sumPayment = schedule.reduce(0.0) { $0 + $1.payment }
        #expect(abs(sumPayment - result.totalPayment) < 0.01)

        // 总利息 = 所有期数利息之和
        let sumInterest = schedule.reduce(0.0) { $0 + $1.interest }
        #expect(abs(sumInterest - result.totalInterest) < 0.01)
    }

    // MARK: - 剩余本金递减验证
    @Test func testRemainingPrincipalDecreasing() {
        var input = LoanInput()
        input.loanAmount = 100
        input.loanTerm = 5
        input.annualRate = 4.2
        input.repaymentMethod = .equalPayment

        let schedule = CalculationEngine.schedule(input: input)

        for i in 1..<schedule.count {
            #expect(schedule[i].remainingPrincipal < schedule[i-1].remainingPrincipal,
                    "第\(i+1)期剩余本金应该小于第\(i)期")
        }
        #expect(schedule.last?.remainingPrincipal == 0, "末月剩余本金应为0")
    }

    // MARK: - 格式化测试
    @Test func testFormatters() {
        #expect(Formatters.currency(4868.33).contains("4868"))   // 带货币符号
        #expect(Formatters.wanYuan(100) == "100.0 万元")        // 万元单位
        #expect(Formatters.wanYuan(1.5) == "1.5 万元")          // 小数
    }
}