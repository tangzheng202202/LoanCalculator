//
//  HistoryManager.swift
//  LoanCalculator
//
//  贷款计算历史记录管理器
//

import Foundation
import Combine

/// 单条历史记录
struct LoanHistoryItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let loanType: String
    let city: String
    let houseType: String
    let houseArea: Double
    let housePricePerSqm: Double
    let downPaymentPercent: Double
    let loanTerm: Int
    let repaymentMethod: String
    let loanAmount: Double
    let monthlyPayment: Double
    let totalInterest: Double
    let totalPayment: Double

    /// 显示标题（如 "组合贷款 · 北京 · 90㎡ · 30年"）
    var displayTitle: String {
        "\(loanType) · \(city) · \(Int(houseArea))㎡ · \(loanTerm)年"
    }

    /// 显示副标题（如 "月供 ¥12,345 · 总利息 ¥987,654"）
    var displaySubtitle: String {
        let mp = Formatters.currency(monthlyPayment)
        let ti = Formatters.currency(totalInterest)
        return "月供 \(mp) · 总利息 \(ti)"
    }

    /// 相对时间显示
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    private let storageKey = "loan_history"
    private let maxItems = 50

    @Published private(set) var items: [LoanHistoryItem] = []

    private init() {
        load()
    }

    // MARK: - 公开方法

    /// 添加一条新记录
    func addRecord(input: LoanInputV2, result: LoanResultV2) {
        let item = LoanHistoryItem(
            id: UUID(),
            createdAt: Date(),
            loanType: input.loanType.rawValue,
            city: input.city.rawValue,
            houseType: input.houseType.rawValue,
            houseArea: input.houseArea,
            housePricePerSqm: input.housePricePerSqm,
            downPaymentPercent: input.downPaymentRatio * 100,
            loanTerm: input.loanTerm,
            repaymentMethod: input.repaymentMethod.rawValue,
            loanAmount: input.loanAmount,
            monthlyPayment: result.totalMonthlyPayment,
            totalInterest: result.totalInterest,
            totalPayment: result.totalPayment
        )
        items.insert(item, at: 0)
        trim()
        save()
    }

    /// 添加 V1 单贷款记录
    func addRecord(input: LoanInput, result: LoanResult) {
        let item = LoanHistoryItem(
            id: UUID(),
            createdAt: Date(),
            loanType: "商业贷款",
            city: "-",
            houseType: "-",
            houseArea: 0,
            housePricePerSqm: 0,
            downPaymentPercent: 0,
            loanTerm: input.loanTerm,
            repaymentMethod: input.repaymentMethod.rawValue,
            loanAmount: input.amountInYuan,
            monthlyPayment: result.monthlyPayment,
            totalInterest: result.totalInterest,
            totalPayment: result.totalPayment
        )
        items.insert(item, at: 0)
        trim()
        save()
    }

    /// 删除一条记录
    func deleteRecord(_ item: LoanHistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    /// 清空全部历史
    func clearAll() {
        items.removeAll()
        save()
    }

    /// 恢复计算参数（生成新的 LoanInputV2）
    func restoreToInput(_ item: LoanHistoryItem) -> LoanInputV2 {
        var input = LoanInputV2()
        input.loanType = LoanType.allCases.first { $0.rawValue == item.loanType } ?? .commercial
        input.city = City.allCases.first { $0.rawValue == item.city } ?? .beijing
        input.houseType = HouseType.allCases.first { $0.rawValue == item.houseType } ?? .first
        input.houseArea = item.houseArea > 0 ? item.houseArea : 90
        input.housePricePerSqm = item.housePricePerSqm > 0 ? item.housePricePerSqm : 50000
        input.downPaymentRatio = item.downPaymentPercent > 0 ? item.downPaymentPercent / 100 : 0.20
        input.loanTerm = item.loanTerm
        input.repaymentMethod = RepaymentMethod.allCases.first { $0.rawValue == item.repaymentMethod } ?? .equalPayment
        return input
    }

    // MARK: - 私有方法

    private func trim() {
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            items = try JSONDecoder().decode([LoanHistoryItem].self, from: data)
        } catch {
            print("历史记录加载失败: \(error.localizedDescription)")
            items = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("历史记录保存失败: \(error.localizedDescription)")
        }
    }
}
