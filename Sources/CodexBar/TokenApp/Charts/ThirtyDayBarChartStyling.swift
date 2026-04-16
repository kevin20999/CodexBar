import Charts
import SwiftUI

struct DashboardThirtyDayChartScale: Equatable {
    let topValue: Double
    let midpointValue: Double

    init(topValue: Double) {
        self.topValue = topValue
        self.midpointValue = topValue / 2
    }

    var axisValues: [Double] {
        [0, self.midpointValue, self.topValue]
    }
}

enum DashboardThirtyDayChartScaleResolver {
    static let targetPeakHeightRatio = 0.96
    static let minimumTopValue = 2.0

    static func topValue(forPeakValue peakValue: Int) -> Double {
        guard peakValue > 0 else { return self.minimumTopValue }
        let visualTopValue = ceil(Double(peakValue) / self.targetPeakHeightRatio)
        return max(self.minimumTopValue, visualTopValue)
    }
}

enum DashboardThirtyDayBarStyle {
    static let barWidth: CGFloat = 11
    static let barCornerRadius: CGFloat = 4.5
    static let peakLabelFontSize: CGFloat = 10
    static let peakLabelMinWidth: CGFloat = 42
    static let peakLabelMaxWidth: CGFloat = 58
    static let peakLabelHorizontalPadding: CGFloat = 10
    static let peakLabelHeight: CGFloat = 18
    static let peakLabelGap: CGFloat = 3
    static let peakLabelTopInset: CGFloat = 3
    static let axisLabelFontSize: CGFloat = 9.5
    static let axisLabelHeight: CGFloat = 12
    static let axisLabelTopGap: CGFloat = 1.5
    static let axisLabelBottomInset: CGFloat = 0.5
    static let axisLabelHorizontalPadding: CGFloat = 1

    static var peakLabelReservedHeight: CGFloat {
        self.peakLabelHeight + self.peakLabelGap + self.peakLabelTopInset
    }

    static var axisLabelReservedHeight: CGFloat {
        self.axisLabelTopGap + self.axisLabelHeight + self.axisLabelBottomInset
    }
}

func dashboardThirtyDayBarStyle() -> AnyShapeStyle {
    AnyShapeStyle(TokenFloatingCardTheme.chartGradient(for: .input))
}

func dashboardThirtyDayBarGlow() -> Color {
    TokenFloatingCardTheme.glowColor(for: .input)
}

func dashboardThirtyDayBarHighlightStart(
    for value: Double,
    scale: DashboardThirtyDayChartScale)
    -> Double
{
    max(value - max(scale.topValue * 0.12, value * 0.22), 0)
}

func dashboardChartBarHighlightStyle(
    usesFloatingLowerCards: Bool,
    emphasized: Bool = false)
    -> AnyShapeStyle
{
    AnyShapeStyle(
        LinearGradient(
            colors: [
                Color.white.opacity(usesFloatingLowerCards ? (emphasized ? 0.42 : 0.34) : (emphasized ? 0.28 : 0.22)),
                Color.white.opacity(0.02),
            ],
            startPoint: .top,
            endPoint: .bottom))
}

func dashboardThirtyDayPeakCapStyle() -> AnyShapeStyle {
    AnyShapeStyle(
        LinearGradient(
            colors: [
                Color(nsColor: .systemYellow),
                Color(nsColor: .systemOrange),
            ],
            startPoint: .leading,
            endPoint: .trailing))
}

func dashboardChartGridTint(usesFloatingLowerCards: Bool) -> Color {
    usesFloatingLowerCards ? TokenFloatingCardTheme.chartGrid : TokenMenuTheme.chartGrid
}

func dashboardChartAxisTint(usesFloatingLowerCards: Bool) -> Color {
    usesFloatingLowerCards ? TokenFloatingCardTheme.chartAxis : TokenMenuTheme.chartAxis
}

func dashboardThirtyDayDisplayedBarValue(
    for value: Int,
    scale: DashboardThirtyDayChartScale)
    -> Double
{
    guard value > 0 else { return 0 }
    let minimumVisibleValue = max(1, Int((scale.topValue * 0.018).rounded(.up)))
    return Double(max(value, minimumVisibleValue))
}

@ChartContentBuilder
func dashboardThirtyDayBarMarks(
    date: Date,
    rawValue: Int,
    displayedValue: Double,
    isPeak: Bool,
    scale: DashboardThirtyDayChartScale,
    usesFloatingLowerCards: Bool,
    peakBubbleText: String? = nil)
    -> some ChartContent
{
    BarMark(
        x: .value("Day", date, unit: .day),
        y: .value("Value", displayedValue),
        width: .fixed(DashboardThirtyDayBarStyle.barWidth))
        .foregroundStyle(dashboardThirtyDayBarStyle())
        .opacity(isPeak ? 1 : 0.72)
        .clipShape(TokenTopRoundedBarShape(radius: DashboardThirtyDayBarStyle.barCornerRadius))
        .shadow(
            color: dashboardThirtyDayBarGlow().opacity(isPeak ? 0.30 : 0.12),
            radius: isPeak ? 8 : 4,
            x: 0,
            y: isPeak ? 1 : 0)

    if displayedValue > 0 {
        BarMark(
            x: .value("Day", date, unit: .day),
            yStart: .value(
                "Value shine start",
                dashboardThirtyDayBarHighlightStart(for: displayedValue, scale: scale)),
            yEnd: .value("Value shine end", displayedValue),
            width: .fixed(DashboardThirtyDayBarStyle.barWidth))
            .foregroundStyle(
                dashboardChartBarHighlightStyle(
                    usesFloatingLowerCards: usesFloatingLowerCards,
                    emphasized: isPeak))
            .opacity(isPeak ? 1 : 0.84)
            .clipShape(TokenTopRoundedBarShape(radius: DashboardThirtyDayBarStyle.barCornerRadius))
    }

    if isPeak, rawValue > 0 {
        BarMark(
            x: .value("Day", date, unit: .day),
            yStart: .value(
                "Peak cap start",
                max(displayedValue - max(scale.topValue * 0.055, 1), 0)),
            yEnd: .value("Peak cap end", displayedValue),
            width: .fixed(DashboardThirtyDayBarStyle.barWidth))
            .foregroundStyle(dashboardThirtyDayPeakCapStyle())
            .clipShape(TokenTopRoundedBarShape(radius: DashboardThirtyDayBarStyle.barCornerRadius))
            .annotation(position: .top, spacing: 4) {
                if let peakBubbleText {
                    dashboardThirtyDayPeakLabel(text: peakBubbleText)
                }
            }
    }
}
