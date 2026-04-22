//
//  DSRGaugeView.swift
//  LoanCalculator
//
//  负债率仪表盘（Debt Service Ratio Gauge）
//

import SwiftUI
import Charts

struct DSRGaugeView: View {
    let assessment: CalculationEngineV2.DSRAssessment
    @State private var animatedDSR: Double = 0

    private var ratingColor: Color {
        switch assessment.rating {
        case .excellent: return .green
        case .good: return .mint
        case .moderate: return .yellow
        case .caution: return .orange
        case .danger: return .red
        }
    }

    private var ratingIcon: String {
        switch assessment.rating {
        case .excellent: return "star.fill"
        case .good: return "checkmark.seal.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .danger: return "xmark.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("还款能力评估")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: ratingIcon)
                        .foregroundColor(ratingColor)
                    Text(assessment.rating.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ratingColor)
                }
            }

            // Gauge arc
            gaugeArc
                .frame(height: 160)

            // DSR percentage + income info
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("月供/月收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(assessment.dsr * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(ratingColor)
                }

                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("月收入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Formatters.currency(assessment.monthlyIncome))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Divider().frame(height: 30)
                    VStack(spacing: 2) {
                        Text("月供")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Formatters.currency(assessment.monthlyPayment))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            Divider()

            // Advice text
            Text(assessment.rating.advice)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Suggested max
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("建议月供上限")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.currency(assessment.suggestedMaxMonthlyPayment))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("建议贷款上限")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(assessment.suggestedMaxLoan / 10000)) 万")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedDSR = assessment.dsr
            }
        }
    }

    // MARK: - Gauge Arc

    private var gaugeArc: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let center = CGPoint(x: width / 2, y: height)
            let radius = min(width, height * 2) * 0.7

            ZStack {
                // Background arc
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(0))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: radius * 2, height: radius)

                // Colored arc segments
                ArcWithGradient(dsr: animatedDSR, radius: radius)

                // Needle
                needleView(radius: radius, center: CGPoint(x: width / 2, y: height))

                // DSR zones labels
                HStack(spacing: 0) {
                    Text("20%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("30%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("40%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("50%+")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: radius * 2)
                .offset(y: radius * 0.6)
            }
            .frame(width: width, height: height)
        }
    }

    private func needleView(radius: CGFloat, center: CGPoint) -> some View {
        let angle = Angle(degrees: 180 + (min(animatedDSR, 0.7) / 0.7) * 180)
        let needleLength = radius * 0.75

        return ZStack {
            // Needle
            Rectangle()
                .fill(ratingColor)
                .frame(width: 4, height: needleLength)
                .offset(y: -needleLength / 2)
                .rotationEffect(angle, anchor: .bottom)

            // Center circle
            Circle()
                .fill(ratingColor)
                .frame(width: 14, height: 14)
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

// MARK: - Arc Shape

struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

// MARK: - Gradient Arc

struct ArcWithGradient: View {
    let dsr: Double
    let radius: CGFloat

    private var segments: [(range: ClosedRange<Double>, color: Color)] {
        [
            (0.0...0.2, .green),
            (0.2...0.3, .mint),
            (0.3...0.4, .yellow),
            (0.4...0.5, .orange),
            (0.5...1.0, .red)
        ]
    }

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                let startDeg = 180 + segment.range.lowerBound / 0.5 * 180
                let endDeg = 180 + min(segment.range.upperBound, 0.7) / 0.5 * 180

                ArcShape(
                    startAngle: .degrees(startDeg),
                    endAngle: .degrees(endDeg)
                )
                .stroke(segment.color.opacity(0.3), lineWidth: 20)
            }

            // Filled portion up to current DSR
            let filledEnd = 180 + min(dsr, 0.7) / 0.5 * 180
            ArcShape(
                startAngle: .degrees(180),
                endAngle: .degrees(filledEnd)
            )
            .stroke(
                LinearGradient(
                    colors: [.green, .mint, .yellow, .orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 20, lineCap: .round)
            )
        }
        .frame(width: radius * 2, height: radius)
    }
}
