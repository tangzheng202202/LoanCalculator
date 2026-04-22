//
//  ResultViewV2.swift
//  LoanCalculator
//
//  扩展的结果界面（支持组合贷款）
//

import SwiftUI

struct ResultViewV2: View {
    let result: LoanResultV2
    let input: LoanInputV2
    @Environment(\.dismiss) private var dismiss

    @State private var showingSchedule = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showExportError = false

    private let primaryColor = Color.mint

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    mainResultCard

                    if input.loanType == .combined {
                        splitResultCard
                    }

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
            .sheet(isPresented: $showingSchedule) {
                ScheduleDetailViewV2(input: input)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
            .alert("导出失败", isPresented: $showExportError) {
                Button("好的") {}
            } message: {
                Text(exportError ?? "未知错误")
            }
            .onAppear {
                // 自动保存到历史记录
                HistoryManager.shared.addRecord(input: input, result: result)
            }
        }
    }

    // MARK: - 主结果卡片

    private var mainResultCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("月供")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(Formatters.currency(result.totalMonthlyPayment))
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

            if result.savedInterest > 0 {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("组合贷比纯商贷节省 \(Formatters.currency(result.savedInterest))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(20)
    }

    // MARK: - 组合贷分栏展示

    private var splitResultCard: some View {
        VStack(spacing: 16) {
            Text("贷款明细")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("公积金贷款")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.wanYuan(result.housingFundPrincipal / 10000))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("\(Int(result.housingFundMonthlyPayment)) 元/月")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                VStack(spacing: 8) {
                    Text("商业贷款")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.wanYuan(result.commercialPrincipal / 10000))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("\(Int(result.commercialMonthlyPayment)) 元/月")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(16)
    }

    // MARK: - 详情部分

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("贷款详情")
                .font(.headline)

            VStack(spacing: 12) {
                detailRow(title: "贷款类型", value: input.loanType.rawValue)
                detailRow(title: "所在城市", value: input.city.rawValue)
                detailRow(title: "房屋总价", value: Formatters.wanYuan(input.totalHousePrice / 10000))
                detailRow(title: "首付金额", value: Formatters.wanYuan(input.downPayment / 10000))
                detailRow(title: "贷款期限", value: "\(input.loanTerm)年")
                detailRow(title: "还款方式", value: input.repaymentMethod.rawValue)

                if input.loanType != .commercial {
                    detailRow(title: "公积金利率", value: String(format: "%.2f%%", input.housingFundRate * 100))
                }

                if input.loanType != .housingFund {
                    detailRow(title: "商业贷款利率", value: String(format: "%.2f%%", input.commercialRate * 100))
                }
            }
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(16)
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

    // MARK: - 操作按钮

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if input.loanType == .combined {
                Button { showingSchedule = true } label: {
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
            }

            HStack(spacing: 12) {
                Button { exportData(type: .csv) } label: {
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

                Button { exportData(type: .pdf) } label: {
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

    private var containerBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color.secondary
        #endif
    }

    private enum ExportType {
        case csv
        case pdf
    }

    private func exportData(type: ExportType) {
        let url: URL?

        switch type {
        case .csv:
            url = ExportManager.exportToCSV(input: input, result: result)
        case .pdf:
            url = ExportManager.exportToPDF(input: input, result: result)
        }

        if let url {
            exportURL = url
            showingShareSheet = true
        } else {
            exportError = "无法生成导出文件，请稍后重试。"
            showExportError = true
        }
    }
}
