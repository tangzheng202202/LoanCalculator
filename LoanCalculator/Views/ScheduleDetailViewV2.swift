//
//  ScheduleDetailViewV2.swift
//  LoanCalculator
//
//  组合贷款明细页面 - 带趋势图
//

import SwiftUI
import Charts

struct ScheduleDetailViewV2: View {
    let input: LoanInputV2
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showChart = false
    
    private let pageSize = 30
    private var schedule: [MonthlyScheduleItemV2] {
        CalculationEngineV2.schedule(input: input)
    }
    private var pagedSchedule: [MonthlyScheduleItemV2] {
        let start = currentPage * pageSize
        let end = min(start + pageSize, schedule.count)
        guard start < schedule.count else { return [] }
        return Array(schedule[start..<end])
    }
    private var totalPages: Int {
        (schedule.count + pageSize - 1) / pageSize
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 趋势图开关
                HStack {
                    Text("还款明细")
                        .font(.headline)
                    Spacer()
                    Button(action: { showChart.toggle() }) {
                        Image(systemName: showChart ? "chart.bar.fill" : "chart.bar")
                    }
                }
                .padding()
                
                if showChart {
                    trendChart
                        .frame(height: 200)
                        .padding()
                }
                
                // 统计卡片
                statsCard
                
                // 双列标题
                headerRow
                
                // 明细列表
                List(pagedSchedule, id: \.month) { item in
                    row(for: item)
                }
                .listStyle(.plain)
                
                // 分页
                if totalPages > 1 {
                    pager
                        .padding(.vertical, 8)
                        .background(containerBackground)
                }
            }
            .navigationTitle("还款明细")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - 趋势图
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("还款趋势")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(schedule.prefix(60)) { item in
                LineMark(
                    x: .value("月份", item.month),
                    y: .value("月供", item.totalPayment)
                )
                .foregroundStyle(Color.mint)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("月份", item.month),
                    y: .value("月供", item.totalPayment)
                )
                .foregroundStyle(Color.mint.opacity(0.1))
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("月份", item.month),
                    y: .value("本金", item.totalPrincipal)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                
                LineMark(
                    x: .value("月份", item.month),
                    y: .value("利息", item.totalInterest)
                )
                .foregroundStyle(Color.orange)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 12)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            
            // 图例
            HStack(spacing: 16) {
                LegendItem(color: .mint, label: "月供")
                LegendItem(color: .blue, label: "本金")
                LegendItem(color: .orange, label: "利息")
            }
            .font(.caption2)
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(12)
    }
    
    // MARK: - 统计卡片
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("首月月供")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.currency(schedule.first?.totalPayment ?? 0))
                        .font(.headline)
                        .foregroundColor(.mint)
                }
                
                Divider().frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("末月月供")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.currency(schedule.last?.totalPayment ?? 0))
                        .font(.headline)
                }
                
                Divider().frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("利息总额")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.wanYuan(schedule.reduce(0) { $0 + $1.totalInterest } / 10000))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(containerBackground)
    }
    
    // MARK: - 表头
    private var headerRow: some View {
        HStack {
            Text("期数")
                .frame(width: 40, alignment: .center)
            Spacer()
            Text("公积金")
                .frame(width: 60, alignment: .trailing)
            Spacer()
            Text("商贷")
                .frame(width: 60, alignment: .trailing)
            Spacer()
            Text("合计")
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - 行数据
    private func row(for item: MonthlyScheduleItemV2) -> some View {
        HStack {
            Text("\(item.month)")
                .frame(width: 40, alignment: .center)
                .font(.caption)
            Spacer()
            Text(Formatters.currency(item.housingFundPayment))
                .frame(width: 60, alignment: .trailing)
                .font(.caption)
                .foregroundColor(.green)
            Spacer()
            Text(Formatters.currency(item.commercialPayment))
                .frame(width: 60, alignment: .trailing)
                .font(.caption)
                .foregroundColor(.blue)
            Spacer()
            Text(Formatters.currency(item.totalPayment))
                .frame(width: 70, alignment: .trailing)
                .font(.caption)
        }
    }
    
    // MARK: - 分页
    private var pager: some View {
        HStack {
            Button(action: { if currentPage > 0 { currentPage -= 1 } }) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage == 0)
            
            Text("第 \(currentPage + 1) / \(totalPages) 页")
                .font(.caption)
            
            Button(action: { if currentPage < totalPages - 1 { currentPage += 1 } }) {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage >= totalPages - 1)
        }
    }
    
    private var containerBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color.secondary
        #endif
    }
}

// MARK: - 图例组件
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}
