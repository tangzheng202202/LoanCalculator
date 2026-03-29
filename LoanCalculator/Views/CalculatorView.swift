//
//  CalculatorView.swift
//  LoanCalculator
//

import SwiftUI

struct CalculatorView: View {
    @State private var input = LoanInput()
    @State private var showingResult = false
    @State private var result: LoanResult?

    private let primaryColor = Color.mint

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    inputSection
                    calculateButton
                }
                .padding()
            }
            .navigationTitle("贷款计算器")
        }
        .sheet(isPresented: $showingResult) {
            if let result = result {
                ResultView(result: result, input: input)
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            repaymentMethodPicker
            inputField(
                title: "贷款金额",
                value: $input.loanAmount,
                unit: "万元",
                range: 1...1000,
                precision: 1,
                step: 1
            )
            inputField(
                title: "贷款期限",
                value: Binding(
                    get: { Double(input.loanTerm) },
                    set: { input.loanTerm = Int($0) }
                ),
                unit: "年",
                range: 1...35,
                precision: 0,
                step: 1
            )
            inputField(
                title: "年利率",
                value: $input.annualRate,
                unit: "%",
                range: 0.1...15,
                precision: 2,
                step: 0.01
            )
        }
    }

    private var repaymentMethodPicker: some View {
        Picker("还款方式", selection: $input.repaymentMethod) {
            ForEach(LoanInput.RepaymentMethod.allCases) { method in
                Text(method.displayName).tag(method)
            }
        }
        .pickerStyle(.segmented)
    }

    private func inputField(
        title: String,
        value: Binding<Double>,
        unit: String,
        range: ClosedRange<Double>,
        precision: Int,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(formatValue(value.wrappedValue, precision: precision))\(unit)")
                    .font(.title3)
                    .foregroundColor(primaryColor)
            }
            Slider(value: value, in: range, step: step)
                .tint(primaryColor)
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(16)
    }

    private func formatValue(_ value: Double, precision: Int) -> String {
        if precision == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.\(precision)f", value)
        }
    }

    private var containerBackground: Color {
        #if canImport(UIKit)
        return Color(.secondarySystemGroupedBackground)
        #else
        return Color.secondary
        #endif
    }

    private var calculateButton: some View {
        Button(action: {
            result = CalculationEngine.calculate(input: input)
            showingResult = true
        }) {
            Text("开始计算")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(primaryColor)
                .cornerRadius(16)
        }
    }
}