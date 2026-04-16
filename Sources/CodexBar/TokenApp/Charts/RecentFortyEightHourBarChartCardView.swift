import AppKit
import Charts
import CodexBarCore
import SwiftUI

typealias RecentFortyEightHourBarChartPoint = RecentTwentyFourHourChartPoint
typealias RecentFortyEightHourBarChartModel = RecentTwentyFourHourChartModel

enum RecentFortyEightHourBarChartModelBuilder {
    static let displayedHourCount = RecentTwentyFourHourChartModelBuilder.displayedHourCount

    static func makeModel(
        from hours: [HourlyTokenStats],
        calendar: Calendar = .current)
        -> RecentFortyEightHourBarChartModel
    {
        RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: calendar)
    }
}

enum RecentFortyEightHourBarChartAxisStripMarkerBuilder {
    private static let domainPadding: Double = 0.35

    static func makeMarkers(
        from markers: [RecentTwentyFourHourChartAxisMarker],
        xDomainUpperBound: Double)
        -> [TokenChartAxisMarker]
    {
        let lowerBound = -self.domainPadding
        let upperBound = xDomainUpperBound + self.domainPadding
        let domainSpan = max(upperBound - lowerBound, 1)

        return markers.map { marker in
            TokenChartAxisMarker(
                id: "slot-\(marker.slotValue)",
                text: marker.text,
                normalizedX: CGFloat((marker.slotValue - lowerBound) / domainSpan),
                priority: self.priority(for: marker.priority))
        }
    }

    private static func priority(
        for priority: RecentTwentyFourHourChartAxisMarker.Priority)
        -> TokenChartAxisMarker.Priority
    {
        switch priority {
        case .normal:
            .normal
        case .compressed:
            .compressed
        case .boundary:
            .boundary
        }
    }
}

@MainActor
struct RecentFortyEightHourBarChartCardView: View {
    private struct Scale {
        let topValue: Double
        let midpointValue: Double

        var axisValues: [Double] {
            [0, self.midpointValue, self.topValue]
        }
    }

    private enum Style {
        static let compactChartHeight: CGFloat = 88
        static let regularChartHeight: CGFloat = 108
        static let compactBarWidth: CGFloat = 8
        static let regularBarWidth: CGFloat = 9
        static let compactBarCornerRadius: CGFloat = 3
        static let regularBarCornerRadius: CGFloat = 4
        static let peakLabelFontSize: CGFloat = 10
        static let peakLabelHorizontalPadding: CGFloat = 10
        static let peakLabelTopPadding: CGFloat = 24
        static let axisLabelFontSize: CGFloat = 7.5
        static let compressedAxisLabelFontSize: CGFloat = 8.5
        static let axisLabelHeight: CGFloat = 10
        static let axisLabelTopGap: CGFloat = 1.5
        static let axisLabelBottomInset: CGFloat = 0.5
        static let axisLabelHorizontalPadding: CGFloat = 0.25

        static var axisLabelReservedHeight: CGFloat {
            self.axisLabelTopGap + self.axisLabelHeight + self.axisLabelBottomInset
        }
    }

    private let hours: [HourlyTokenStats]
    private let strings: AppStrings
    private let compact: Bool
    private let usesFloatingStyle: Bool
    private let model: RecentFortyEightHourBarChartModel
    @Environment(\.colorScheme) private var colorScheme

    init(
        hours: [HourlyTokenStats],
        strings: AppStrings,
        compact: Bool = false,
        usesFloatingStyle: Bool = false)
    {
        self.hours = hours
        self.strings = strings
        self.compact = compact
        self.usesFloatingStyle = usesFloatingStyle
        self.model = RecentFortyEightHourBarChartModelBuilder.makeModel(from: hours)
    }

    private var secondaryText: Color {
        self.usesFloatingStyle ? TokenFloatingCardTheme.secondaryText : TokenMenuTheme.secondaryText
    }

    private var isDarkMode: Bool {
        self.colorScheme == .dark
    }

    private var axisTint: Color {
        TokenRecentHistoryTheme.palette(for: self.isDarkMode).axis
    }

    private var boundaryAxisTint: Color {
        TokenRecentHistoryTheme.palette(for: self.isDarkMode).boundaryAxis
    }

    private var compressedAxisTint: Color {
        TokenRecentHistoryTheme.palette(for: self.isDarkMode).compressedAxis
    }

    private var gridTint: Color {
        TokenRecentHistoryTheme.palette(for: self.isDarkMode).grid
    }

    private var chartHeight: CGFloat {
        self.compact ? Style.compactChartHeight : Style.regularChartHeight
    }

    private var chartPlotHeight: CGFloat {
        max(self.chartHeight - Style.axisLabelReservedHeight, 1)
    }

    private var barWidth: CGFloat {
        self.compact ? Style.compactBarWidth : Style.regularBarWidth
    }

    private var barCornerRadius: CGFloat {
        self.compact ? Style.compactBarCornerRadius : Style.regularBarCornerRadius
    }

    private var yGridOpacity: Double {
        self.isDarkMode ? 0.22 : 0.32
    }

    private var xGridOpacity: Double {
        self.isDarkMode ? 0.12 : 0.16
    }

    private var barStyle: AnyShapeStyle {
        AnyShapeStyle(TokenFloatingCardTheme.chartGradient(for: .input))
    }

    private var barGlow: Color {
        TokenFloatingCardTheme.glowColor(for: .input)
    }

    private var barHighlightStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color.white.opacity(self.usesFloatingStyle ? 0.34 : 0.24),
                    Color.white.opacity(0.02),
                ],
                startPoint: .top,
                endPoint: .bottom))
    }

    private var peakCapStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(nsColor: .systemYellow),
                    Color(nsColor: .systemOrange),
                ],
                startPoint: .leading,
                endPoint: .trailing))
    }

    var body: some View {
        let scale = Self.scale(for: self.model)
        let axisLabelMarkers = self.axisLabelMarkers(for: self.model)
        let axisStripMarkers = RecentFortyEightHourBarChartAxisStripMarkerBuilder.makeMarkers(
            from: axisLabelMarkers,
            xDomainUpperBound: self.model.xDomainUpperBound)

        VStack(alignment: .leading, spacing: self.compact ? 6 : 8) {
            if self.model.hasData {
                VStack(alignment: .leading, spacing: 0) {
                    Chart(self.model.points) { point in
                        let displayedValue = self.displayedBarValue(for: point.totalTokens, scale: scale)
                        let isPeak = point.id == self.model.peakPoint?.id && point.totalTokens > 0

                        if displayedValue > 0 {
                            BarMark(
                                x: .value("Hour slot", point.slotValue),
                                y: .value("Tokens", displayedValue),
                                width: .fixed(self.barWidth))
                                .foregroundStyle(self.barStyle)
                                .clipShape(TokenTopRoundedBarShape(radius: self.barCornerRadius))
                                .shadow(
                                    color: self.barGlow.opacity(self.usesFloatingStyle ? 0.24 : 0.14),
                                    radius: self.usesFloatingStyle ? 9 : 5,
                                    x: 0,
                                    y: self.usesFloatingStyle ? 4 : 2)

                            BarMark(
                                x: .value("Hour slot", point.slotValue),
                                yStart: .value(
                                    "Token shine start",
                                    self.barHighlightStart(for: displayedValue, scale: scale)),
                                yEnd: .value("Token shine end", displayedValue),
                                width: .fixed(self.barWidth))
                                .foregroundStyle(self.barHighlightStyle)
                                .clipShape(TokenTopRoundedBarShape(radius: self.barCornerRadius))
                        }

                        if isPeak {
                            BarMark(
                                x: .value("Hour slot", point.slotValue),
                                yStart: .value(
                                    "Peak cap start",
                                    max(displayedValue - max(scale.topValue * 0.055, 1), 0)),
                                yEnd: .value("Peak cap end", displayedValue),
                                width: .fixed(self.barWidth))
                                .foregroundStyle(self.peakCapStyle)
                                .clipShape(TokenTopRoundedBarShape(radius: self.barCornerRadius))
                                .annotation(position: .top, spacing: 4) {
                                    self.peakLabel(
                                        text: self.strings.recentTwentyFourHourPeakBubbleText(point.totalTokens))
                                }
                        }
                    }
                    .chartXScale(domain: -0.35...(self.model.xDomainUpperBound + 0.35))
                    .chartYScale(domain: 0...scale.topValue)
                    .chartPlotStyle { plot in
                        plot
                            .padding(.top, Style.peakLabelTopPadding)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: scale.axisValues) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [3, 5]))
                                .foregroundStyle(self.gridTint.opacity(self.yGridOpacity))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: axisLabelMarkers.map(\.slotValue)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.35, dash: [2, 6]))
                                .foregroundStyle(self.gridTint.opacity(self.xGridOpacity))
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: self.chartPlotHeight)

                    TokenChartBottomAxisStrip(
                        markers: axisStripMarkers,
                        frameHeight: Style.axisLabelReservedHeight,
                        rowCenterY: Style.axisLabelTopGap + (Style.axisLabelHeight / 2),
                        labelWidth: { marker in
                            self.axisLabelWidth(for: marker)
                        },
                        label: { marker, alignment in
                            self.axisLabel(
                                text: marker.text,
                                priority: self.axisLabelPriority(for: marker.priority),
                                alignment: alignment)
                                .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
                                .padding(.horizontal, Style.axisLabelHorizontalPadding)
                                .fixedSize(horizontal: false, vertical: true)
                        })
                }
                .frame(height: self.chartHeight)
            } else {
                Text(self.strings.noRecentFortyEightHourData)
                    .font(self.compact ? .caption : .footnote)
                    .foregroundStyle(self.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func axisLabelWidth(for marker: TokenChartAxisMarker) -> CGFloat {
        let priority = self.axisLabelPriority(for: marker.priority)
        return dashboardChartTextWidth(
            marker.text,
            font: .systemFont(
                ofSize: self.axisLabelFontSize(for: priority),
                weight: self.axisLabelFontWeight(for: priority)))
            + (Style.axisLabelHorizontalPadding * 2)
    }

    private func axisLabelPriority(
        for priority: TokenChartAxisMarker.Priority)
        -> RecentTwentyFourHourChartAxisMarker.Priority
    {
        switch priority {
        case .normal:
            .normal
        case .compressed:
            .compressed
        case .boundary:
            .boundary
        }
    }

    private func axisLabelFontWeight(for priority: RecentTwentyFourHourChartAxisMarker.Priority) -> NSFont.Weight {
        switch priority {
        case .compressed, .boundary:
            .semibold
        case .normal:
            .medium
        }
    }

    private func axisLabel(
        text: String,
        priority: RecentTwentyFourHourChartAxisMarker.Priority,
        alignment: ThirtyDayChartAxisLabelResolver.TextAlignment)
        -> some View
    {
        Text(text)
            .font(.system(size: self.axisLabelFontSize(for: priority), weight: self.axisLabelTextWeight(for: priority)))
            .foregroundStyle(self.axisLabelTint(for: priority))
            .lineLimit(1)
            .minimumScaleFactor(0.88)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
    }

    private static func scale(for model: RecentFortyEightHourBarChartModel) -> Scale {
        let peakValue = max(model.peakPoint?.totalTokens ?? 0, 1)
        let topValue = max(2.0, ceil(Double(peakValue) / 0.96))
        return Scale(topValue: topValue, midpointValue: topValue / 2)
    }

    private func displayedBarValue(for value: Int, scale: Scale) -> Double {
        guard value > 0 else { return 0 }
        let minimumVisibleValue = max(1, Int((scale.topValue * 0.018).rounded(.up)))
        return Double(max(value, minimumVisibleValue))
    }

    private func barHighlightStart(for value: Double, scale: Scale) -> Double {
        max(value - max(scale.topValue * 0.12, value * 0.22), 0)
    }

    private func peakLabel(text: String) -> some View {
        Text(text)
            .font(.system(size: Style.peakLabelFontSize, weight: .bold))
            .foregroundStyle(TokenFloatingCardTheme.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, Style.peakLabelHorizontalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(TokenFloatingCardTheme.cardTop.opacity(0.94))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(TokenFloatingCardTheme.stroke.opacity(0.9), lineWidth: 0.75)
                    }
            }
            .shadow(color: self.barGlow.opacity(0.20), radius: 8, x: 0, y: 2)
    }

    private func axisLabelMarkers(
        for model: RecentFortyEightHourBarChartModel)
        -> [RecentTwentyFourHourChartAxisMarker]
    {
        let orderedMarkers = model.axisMarkers.sorted { $0.slotValue < $1.slotValue }
        guard !orderedMarkers.isEmpty else { return [] }

        var selectedByValue: [Double: RecentTwentyFourHourChartAxisMarker] = [:]

        if let first = orderedMarkers.first {
            selectedByValue[first.slotValue] = first
        }
        if let last = orderedMarkers.last {
            selectedByValue[last.slotValue] = last
        }

        for marker in orderedMarkers where marker.priority == .compressed {
            selectedByValue[marker.slotValue] = marker
        }

        let preferredCount = 5
        if selectedByValue.count < preferredCount {
            let normalMarkers = orderedMarkers.filter { $0.priority == .normal }
            let remainingCount = preferredCount - selectedByValue.count
            for marker in self.sampleMarkers(normalMarkers, targetCount: remainingCount) {
                selectedByValue[marker.slotValue] = marker
            }
        }

        return selectedByValue.values.sorted { $0.slotValue < $1.slotValue }
    }

    private func sampleMarkers(
        _ markers: [RecentTwentyFourHourChartAxisMarker],
        targetCount: Int)
        -> [RecentTwentyFourHourChartAxisMarker]
    {
        guard targetCount > 0, !markers.isEmpty else { return [] }
        guard markers.count > targetCount else { return markers }

        let strideLength = Double(markers.count - 1) / Double(targetCount + 1)
        return (1...targetCount).compactMap { index in
            let resolvedIndex = Int((Double(index) * strideLength).rounded())
            let clampedIndex = min(max(resolvedIndex, 0), markers.count - 1)
            return markers[clampedIndex]
        }
    }

    private func axisLabelFontSize(for priority: RecentTwentyFourHourChartAxisMarker.Priority) -> CGFloat {
        priority == .compressed ? Style.compressedAxisLabelFontSize : Style.axisLabelFontSize
    }

    private func axisLabelTextWeight(for priority: RecentTwentyFourHourChartAxisMarker.Priority) -> Font.Weight {
        switch priority {
        case .compressed, .boundary:
            .semibold
        case .normal:
            .medium
        }
    }

    private func axisLabelTint(for priority: RecentTwentyFourHourChartAxisMarker.Priority) -> Color {
        switch priority {
        case .compressed:
            self.compressedAxisTint
        case .boundary:
            self.boundaryAxisTint
        case .normal:
            self.axisTint
        }
    }
}
