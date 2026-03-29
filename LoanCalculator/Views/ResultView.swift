//
//  ResultView.swift
//  LoanCalculator
//

import SwiftUI

struct ResultView: View {
    let result: LoanResult
    let input: LoanInput
    @Environment(\.dismiss) private var dismiss

    @State private var showingMonthlyDetail = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var exportErrorMessage: String?
    @State private var showErrorAlert = false

    private let primaryColor = Color.mint

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    mainResultCard
                    detailSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("计算结果")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showingMonthlyDetail) {
                MonthlyDetailView(input: input)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let exportURL {
                    ShareSheet(activityItems: [exportURL])
                } else {
                    Text("导出失败，请重试。")
                }
            }
            .alert("导出失败", isPresented: $showErrorAlert) {
                Button("好的") { }
            } message: {
                Text(exportErrorMessage ?? "")
            }
        }
    }

    private var mainResultCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("月供")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(Formatters.currency(result.monthlyPayment))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(primaryColor)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("还款总额")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.currency(result.totalPayment))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider().frame(height: 40)

                VStack(spacing: 4) {
                    Text("支付利息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.currency(result.totalInterest))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(20)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("贷款详情")
                .font(.headline)

            VStack(spacing: 12) {
                detailRow(title: "贷款金额", value: Formatters.wanYuan(input.loanAmount))
                detailRow(title: "贷款期限", value: "\(input.loanTerm)年")
                detailRow(title: "年利率", value: String(format: "%.2f%%", input.annualRate))
                detailRow(title: "还款方式", value: input.repaymentMethod.displayName)
            }
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(16)
    }

    private var containerBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color.secondary
        #endif
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingMonthlyDetail = true }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                    Text("查看每月明细")
                }
                .font(.title3)
                .foregroundColor(primaryColor)
                .frame(maxWidth: .infinity)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(primaryColor, lineWidth: 2)
                )
            }

            HStack(spacing: 12) {
                Button(action: { export(type: .csv) }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("导出CSV")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryColor)
                    .cornerRadius(12)
                }

                Button(action: { export(type: .pdf) }) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("导出PDF")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryColor)
                    .cornerRadius(12)
                }
            }
        }
    }

    private enum ExportType {
        case csv
        case pdf
    }

    private func export(type: ExportType) {
        let exportResult: URL?
        switch type {
        case .csv:
            exportResult = ExportManager.exportToCSV(input: input, result: result)
        case .pdf:
            exportResult = ExportManager.exportToPDF(input: input, result: result)
        }

        if let url = exportResult {
            exportURL = url
            showingShareSheet = true
        } else {
            exportErrorMessage = "无法生成导出文件，请检查存储权限或稍后重试。"
            showErrorAlert = true
        }
    }
}