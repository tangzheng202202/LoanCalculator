//
//  CalculatorViewV2.swift
//  LoanCalculator
//
//  贷款计算器 V2 - 简洁版（修复完善版）
//  支持商业贷款、公积金贷款、公积金组合贷款
//

import SwiftUI

struct CalculatorViewV2: View {
    @State private var loanType: LoanType = .combined
    @State private var city: City = .beijing
    @State private var houseType: HouseType = .first

    @State private var houseArea: Double = 90
    @State private var housePricePerSqm: Double = 50000
    @State private var downPaymentPercent: Double = 20

    @State private var loanTerm: Int = 30
    @State private var repaymentMethod: RepaymentMethod = .equalPayment

    @State private var housingFundEnabled: Bool = true
    @State private var housingFundBalance: Double = 50000
    @State private var housingFundMonthly: Double = 3000
    @State private var spouseHousingFund: Bool = false
    @State private var spouseHousingFundBalance: Double = 0

    @State private var floatingBP: Double = -50

    @State private var showingResult = false
    @State private var result: LoanResultV2?
    @State private var validationErrors: [String] = []
    @State private var showValidationAlert = false

    private let primaryColor = Color.mint

    // MARK: - 计算属性

    private var totalHousePrice: Double { houseArea * housePricePerSqm }
    private var downPayment: Double { totalHousePrice * (downPaymentPercent / 100) }
    private var loanAmount: Double { totalHousePrice - downPayment }

    private var housingFundLoanable: Double {
        city.calculateHousingFundLoanable(
            balance: housingFundBalance,
            spouseBalance: spouseHousingFund ? spouseHousingFundBalance : 0,
            housePrice: totalHousePrice,
            houseType: houseType
        )
    }

    private var commercialRate: Double {
        city.lprBase + (floatingBP / 10000)
    }

    /// 根据城市和房屋类型获取默认 BP
    private var defaultFloatingBP: Double {
        let floating = houseType == .first
            ? city.commercialFloatingFirst
            : city.commercialFloatingSecond
        return floating * 10000
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    typeSection
                    citySection
                    houseSection
                    paramsSection

                    if loanType != .commercial {
                        housingFundSection
                    }

                    if loanType != .housingFund {
                        commercialSection
                    }

                    calculateButton
                }
                .padding()
            }
            .navigationTitle("贷款计算器")
            .alert("输入有误", isPresented: $showValidationAlert) {
                Button("好的") {}
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
        .sheet(isPresented: $showingResult) {
            if let result = result {
                ResultViewV2(result: result, input: buildInput())
            }
        }
        .onAppear {
            floatingBP = defaultFloatingBP
        }
        .onChange(of: city) { newCity in
            floatingBP = computeDefaultBP(for: newCity, houseType: houseType)
        }
        .onChange(of: houseType) { newType in
            floatingBP = computeDefaultBP(for: city, houseType: newType)
        }
    }

    // MARK: - 组件

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("贷款类型").font(.headline)
            Picker("类型", selection: $loanType) {
                ForEach(LoanType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var citySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("城市").font(.headline)
            Picker("城市", selection: $city) {
                ForEach(City.allCases, id: \.self) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .pickerStyle(.menu)
            Text("公积金最高可贷 \(Int(city.maxHousingFundLoan)) 万")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var houseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("房屋信息").font(.headline)

            HStack {
                Text("房屋类型")
                Spacer()
                Picker("房屋类型", selection: $houseType) {
                    ForEach(HouseType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            HStack {
                Text("面积")
                Spacer()
                TextField("90", value: $houseArea, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                Text("㎡")
            }

            HStack {
                Text("单价")
                Spacer()
                TextField("50000", value: $housePricePerSqm, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                Text("元/㎡")
            }

            Divider()

            HStack {
                Text("房屋总价")
                Spacer()
                Text("\(Int(totalHousePrice / 10000)) 万")
                    .font(.headline).foregroundColor(primaryColor)
            }

            HStack {
                Text("首付比例")
                Spacer()
                TextField("20", value: $downPaymentPercent, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                Text("%")
                    .foregroundColor(.secondary)
            }
            Slider(value: $downPaymentPercent, in: 20...99, step: 1)
                .tint(primaryColor)

            Divider()

            HStack {
                Text("首付金额")
                Spacer()
                Text("\(Int(downPayment / 10000)) 万")
                    .font(.headline).foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var paramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("贷款参数").font(.headline)

            HStack {
                Text("贷款期限")
                Spacer()
                Picker("年限", selection: $loanTerm) {
                    ForEach(Array(1...35), id: \.self) { year in
                        Text("\(year)年").tag(year)
                    }
                }.frame(width: 100)
            }

            Picker("还款方式", selection: $repaymentMethod) {
                ForEach(RepaymentMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }.pickerStyle(.segmented)

            Divider()

            HStack {
                Text("贷款金额")
                Spacer()
                Text("\(Int(loanAmount / 10000)) 万")
                    .font(.title3.bold()).foregroundColor(primaryColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var housingFundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("公积金贷款").font(.headline)
                Spacer()
                Toggle("", isOn: $housingFundEnabled).labelsHidden()
            }

            if housingFundEnabled {
                HStack {
                    Text("账户余额")
                    Spacer()
                    TextField("50000", value: $housingFundBalance, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                    Text("元")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("月缴存")
                    Spacer()
                    TextField("3000", value: $housingFundMonthly, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text("元")
                        .foregroundColor(.secondary)
                }

                Toggle("配偶共用", isOn: $spouseHousingFund)

                if spouseHousingFund {
                    HStack {
                        Text("配偶余额")
                        Spacer()
                        TextField("0", value: $spouseHousingFundBalance, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("元")
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                HStack {
                    Text("可贷额度")
                    Spacer()
                    Text("\(Int(min(housingFundLoanable, loanAmount) / 10000)) 万")
                        .font(.headline).foregroundColor(.green)
                }

                Text("公积金利率：\(String(format: "%.2f%%", (houseType == .first ? city.housingFundRateFirst : city.housingFundRateSecond) * 100))")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var commercialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("商业贷款").font(.headline)

            HStack {
                Text("LPR基准")
                Spacer()
                Text("3.5%")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("BP浮动")
                Spacer()
                TextField("-50", value: $floatingBP, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                    .multilineTextAlignment(.trailing)
                Text("BP")
                    .foregroundColor(.secondary)
            }
            Slider(value: $floatingBP, in: -100...100, step: 1)
                .tint(primaryColor)

            Divider()

            HStack {
                Text("实际利率")
                Spacer()
                Text("\(commercialRate * 100, specifier: "%.2f")%")
                    .font(.headline).foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var calculateButton: some View {
        Button {
            performCalculate()
        } label: {
            Text("开始计算")
                .font(.headline).bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(primaryColor)
                .cornerRadius(12)
        }
    }

    // MARK: - 私有方法

    private func computeDefaultBP(for city: City, houseType: HouseType) -> Double {
        let floating = houseType == .first
            ? city.commercialFloatingFirst
            : city.commercialFloatingSecond
        return floating * 10000
    }

    private func performCalculate() {
        let input = buildInput()
        if !input.validate() {
            validationErrors = input.validationErrors
            showValidationAlert = true
            return
        }
        result = CalculationEngineV2.calculate(input: input)
        showingResult = true
    }

    private func buildInput() -> LoanInputV2 {
        var input = LoanInputV2()
        input.loanType = loanType
        input.city = city
        input.houseType = houseType
        input.houseArea = houseArea
        input.housePricePerSqm = housePricePerSqm
        input.downPaymentRatio = downPaymentPercent / 100
        input.loanTerm = loanTerm
        input.repaymentMethod = repaymentMethod
        input.housingFundEnabled = housingFundEnabled
        input.housingFundBalance = housingFundBalance
        input.housingFundMonthly = housingFundMonthly
        input.spouseHousingFund = spouseHousingFund
        input.spouseHousingFundBalance = spouseHousingFundBalance
        input.floatingRatio = floatingBP / 10000
        return input
    }
}
