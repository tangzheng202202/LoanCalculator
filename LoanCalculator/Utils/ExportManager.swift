//
//  ExportManager.swift
//  LoanCalculator
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

class ExportManager {
    static func exportToCSV(input: LoanInputV2, result: LoanResultV2) -> URL? {
        let prefix = input.city == .beijing && result.housingFundPrincipal > 0 ? "方案测算明细" : "贷款明细"
        let filename = "\(prefix)_\(Int(result.loanAmount.rounded()))元_\(input.loanTerm)年.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        var csv = "月份,月供,本金,利息,剩余本金\n"

        let schedule = CalculationEngineV2.schedule(input: input)

        for detail in schedule {
            let payment = String(format: "%.2f", detail.totalPayment)
            let principal = String(format: "%.2f", detail.totalPrincipal)
            let interest = String(format: "%.2f", detail.totalInterest)
            let remaining = String(format: "%.2f", detail.remainingPrincipal)

            csv += "\(detail.month),\(payment),\(principal),\(interest),\(remaining)\n"
        }

        do {
            try csv.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            return nil
        }
    }

#if canImport(UIKit)
    static func exportToPDF(input: LoanInputV2, result: LoanResultV2) -> URL? {
        let prefix = input.city == .beijing && result.housingFundPrincipal > 0 ? "方案测算明细" : "贷款明细"
        let filename = "\(prefix)_\(Int(result.loanAmount.rounded()))元_\(input.loanTerm)年.pdf"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let pageSize = CGSize(width: 595, height: 842)
        let margin: CGFloat = 32
        let lineHeight: CGFloat = 18

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        do {
            try renderer.writePDF(to: path) { context in
                context.beginPage()
                var yOffset = margin

                func addLine(_ text: String, attributes: [NSAttributedString.Key: Any]?) {
                    let attributed = NSAttributedString(string: text, attributes: attributes)
                    attributed.draw(at: CGPoint(x: margin, y: yOffset))
                    yOffset += lineHeight

                    if yOffset + margin > pageSize.height {
                        context.beginPage()
                        yOffset = margin
                    }
                }

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18)
                ]
                let normalAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]

                addLine("贷款计算结果", attributes: titleAttributes)
                addLine("", attributes: normalAttributes)
                addLine("贷款金额：\(Formatters.wanYuan(result.loanAmount / 10000))", attributes: normalAttributes)
                if input.city == .beijing && result.housingFundPrincipal > 0 {
                    addLine("北京公积金部分为方案测算本金，不代表获批额度；实际额度以审批为准。", attributes: normalAttributes)
                }
                addLine("贷款期限：\(input.loanTerm)年", attributes: normalAttributes)
                if result.housingFundPrincipal > 0 {
                    addLine("公积金利率：\(String(format: "%.2f%%", input.housingFundRate * 100))", attributes: normalAttributes)
                }
                if result.commercialPrincipal > 0 {
                    addLine("商业贷款测算利率：\(String(format: "%.2f%%", input.commercialRate * 100))", attributes: normalAttributes)
                    if input.city == .beijing {
                        addLine("商业贷款实际利率以经办银行报价为准。", attributes: normalAttributes)
                    }
                }
                addLine("月供：\(Formatters.currency(result.totalMonthlyPayment))", attributes: normalAttributes)
                addLine("总还款：\(Formatters.currency(result.totalPayment))", attributes: normalAttributes)
                addLine("支付利息：\(Formatters.currency(result.totalInterest))", attributes: normalAttributes)
                addLine("", attributes: normalAttributes)
                addLine("每月明细：", attributes: titleAttributes)
                addLine("月份, 月供, 本金, 利息, 剩余本金", attributes: normalAttributes)

                for detail in CalculationEngineV2.schedule(input: input) {
                    addLine(
                        "\(detail.month), \(Formatters.currency(detail.totalPayment)), \(Formatters.currency(detail.totalPrincipal)), \(Formatters.currency(detail.totalInterest)), \(Formatters.currency(detail.remainingPrincipal))",
                        attributes: normalAttributes
                    )
                }
            }

            return path
        } catch {
            return nil
        }
    }
#else
    static func exportToPDF(input: LoanInputV2, result: LoanResultV2) -> URL? {
        nil
    }
#endif

#if canImport(UIKit)
    static func shareFile(url: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
#endif
}
