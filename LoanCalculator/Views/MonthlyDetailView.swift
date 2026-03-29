//
//  MonthlyDetailView.swift
//  LoanCalculator
//

import SwiftUI

struct MonthlyDetailView: View {
    let input: LoanInput
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var currentPage: Int = 0

    private let pageSize = 30

    private var schedule: [MonthlyDetail] {
        CalculationEngine.schedule(input: input)
    }

    private var filteredSchedule: [MonthlyDetail] {
        guard !searchText.isEmpty, let month = Int(searchText) else { return schedule }
        return schedule.filter { $0.month == month }
    }

    private var pagedSchedule: [MonthlyDetail] {
        let items = filteredSchedule
        let startIndex = currentPage * pageSize
        guard startIndex < items.count else { return [] }
        return Array(items[startIndex..<min(items.count, startIndex + pageSize)])
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(filteredSchedule.count) / Double(pageSize))))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                List(pagedSchedule, id: \.month) { detail in
                    row(for: detail)
                }
                .listStyle(.plain)

                if filteredSchedule.count > pageSize {
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
            .onChange(of: filteredSchedule.count) { _ in
                currentPage = 0
            }
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("输入月份过滤（如 12）", text: $searchText)
#if canImport(UIKit)
        .keyboardType(.numberPad)
        #endif
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private func row(for detail: MonthlyDetail) -> some View {
        HStack {
            Text("第\(detail.month)月")
                .font(.caption)
                .frame(width: 60, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.currency(detail.payment))
                    .font(.caption)
                    .fontWeight(.medium)
                Text("本金: \(Formatters.currency(detail.principal))")
                    .font(.caption2)
                    .foregroundColor(.mint)
                Text("利息: \(Formatters.currency(detail.interest))")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }

    private var pager: some View {
        HStack {
            Button(action: { currentPage = max(0, currentPage - 1) }) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage == 0)

            Spacer()

            Text("第 \(currentPage + 1) / \(pageCount) 页")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: { currentPage = min(pageCount - 1, currentPage + 1) }) {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage >= pageCount - 1)
        }
        .padding(.horizontal)
    }

    private var containerBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color.secondary
        #endif
    }
}
