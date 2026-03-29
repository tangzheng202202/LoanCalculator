//
//  ExportManager.swift
//  LoanCalculator
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

class ExportManager {
    static func exportToCSV(input: LoanInput, result: LoanResult) -> URL? {
        let filename = "贷款明细_\(Int(input.loanAmount))万_\(input.loanTerm)年.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        var csv = "月份,月供,本金,利息,剩余本金\n"

        let schedule = CalculationEngine.schedule(input: input)

        for detail in schedule {
            let payment = String(format: "%.2f", detail.payment)
            let principal = String(format: "%.2f", detail.principal)
            let interest = String(format: "%.2f", detail.interest)
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
    static func exportToPDF(input: LoanInput, result: LoanResult) -> URL? {
        let filename = "贷款明细_\(Int(input.loanAmount))万_\(input.loanTerm)年.pdf"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let pageSize = CGSize(width: 595, height: 842)
        let margin: CGFloat = 32
        let lineHeight: CGFloat = 18

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        do {
            try renderer.writePDF(to: path) { context in
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

                let rateText = String(format: "%.2f%%", input.annualRate)

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18)
                ]
                let normalAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]

                addLine("贷款计算结果", attributes: titleAttributes)
                addLine("", attributes: normalAttributes)
                addLine("贷款金额：\(Formatters.wanYuan(input.loanAmount))", attributes: normalAttributes)
                addLine("贷款期限：\(input.loanTerm)年", attributes: normalAttributes)
                addLine("年利率：\(rateText)", attributes: normalAttributes)
                addLine("月供：\(Formatters.currency(result.monthlyPayment))", attributes: normalAttributes)
                addLine("总还款：\(Formatters.currency(result.totalPayment))", attributes: normalAttributes)
                addLine("支付利息：\(Formatters.currency(result.totalInterest))", attributes: normalAttributes)
                addLine("", attributes: normalAttributes)
                addLine("每月明细：", attributes: titleAttributes)
                addLine("月份, 月供, 本金, 利息, 剩余本金", attributes: normalAttributes)

                for detail in CalculationEngine.schedule(input: input) {
                    addLine(
                        "\(detail.month), \(Formatters.currency(detail.payment)), \(Formatters.currency(detail.principal)), \(Formatters.currency(detail.interest)), \(Formatters.currency(detail.remainingPrincipal))",
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
    static func exportToPDF(input: LoanInput, result: LoanResult) -> URL? {
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
