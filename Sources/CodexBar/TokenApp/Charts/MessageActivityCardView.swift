import Charts
import CodexBarCore
import SwiftUI

enum MessageActivityCardLayoutMetrics {
    static let usesInsetSummaryBackground = false
    static let showsChartSubtitle = false
    static let usesStackedSummaryColumns = true
    static let summaryColumnCount = 4
    static let summaryRowCount = 1
    static let rootSpacing: CGFloat = 6
    static let summaryHorizontalPadding: CGFloat = 2
    static let summaryVerticalPadding: CGFloat = 2
    static let metricLabelFontSize: CGFloat = 10
    static let metricValueFontSize: CGFloat = 21
    static let metricLabelTopSpacing: CGFloat = 2
    static let matrixColumnSpacing: CGFloat = 10
    static let miniChartSpacing: CGFloat = 0
    static let miniChartHeight: CGFloat = 78
    static let sectionDividerOpacity: Double = 0.34
    static let columnDividerOpacity: Double = 0.14
}

struct MessageActivityCardPoint: Identifiable, Equatable {
    let date: Date
    let stats: DailyOutboundMessageStats

    var id: String {
        self.stats.id
    }
}

struct MessageActivityCardModel: Equatable {
    let todayTotal: DailyOutboundMessageStats
    let sevenDayTotal: DailyOutboundMessageStats
    let thirtyDayTotal: DailyOutboundMessageStats
    let cumulativeTotal: DailyOutboundMessageStats
    let points: [MessageActivityCardPoint]
    let axisDates: [Date]
    let axisMarkers: [TokenChartAxisMarker]
    let peakPointID: String?
    let scale: DashboardThirtyDayChartScale

    var hasData: Bool {
        self.cumulativeTotal.characterCount > 0 || self.cumulativeTotal.instructionCount > 0
    }
}

enum MessageActivityCardModelBuilder {
    static let displayedDayCount = 30
    static let axisAnchorCount = 5

    static func makeModel(
        days: [DailyOutboundMessageStats],
        todayTotal: DailyOutboundMessageStats,
        sevenDayTotal: DailyOutboundMessageStats,
        thirtyDayTotal: DailyOutboundMessageStats,
        cumulativeTotal: DailyOutboundMessageStats,
        referenceDate: Date = Date(),
        locale: Locale = .current,
        calendar: Calendar = .current)
        -> MessageActivityCardModel
    {
        let todayStart = calendar.startOfDay(for: referenceDate)
        let knownDays = Dictionary(uniqueKeysWithValues: days.map { ($0.date, $0) })
        let points = (0..<self.displayedDayCount).reversed().compactMap { offset -> MessageActivityCardPoint? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else {
                return nil
            }
            let key = DailyTokenStats.dayKey(for: day, calendar: calendar)
            let stats = knownDays[key] ?? .empty(for: key)
            return MessageActivityCardPoint(date: day, stats: stats)
        }

        let peakValue = points.map(\.stats.instructionCount).max() ?? 0
        let peakPointID = self.peakPointID(for: points)
        let axisAnchorIndices = self.axisAnchorIndices(for: points.count)
        let axisDates = axisAnchorIndices.map { points[$0].date }
        let axisMarkers = self.axisMarkers(
            for: points,
            indices: axisAnchorIndices,
            locale: locale,
            calendar: calendar)

        return MessageActivityCardModel(
            todayTotal: todayTotal,
            sevenDayTotal: sevenDayTotal,
            thirtyDayTotal: thirtyDayTotal,
            cumulativeTotal: cumulativeTotal,
            points: points,
            axisDates: axisDates,
            axisMarkers: axisMarkers,
            peakPointID: peakPointID,
            scale: DashboardThirtyDayChartScale(
                topValue: DashboardThirtyDayChartScaleResolver.topValue(forPeakValue: peakValue)))
    }

    private static func axisAnchorIndices(for pointCount: Int) -> [Int] {
        guard pointCount > 0 else { return [] }
        guard pointCount > self.axisAnchorCount else {
            return Array(0..<pointCount)
        }

        var resolvedIndices: [Int] = []
        for anchor in 0..<self.axisAnchorCount {
            let progress = Double(anchor) / Double(max(self.axisAnchorCount - 1, 1))
            let index = Int((Double(pointCount - 1) * progress).rounded())
            if resolvedIndices.last != index {
                resolvedIndices.append(index)
            }
        }

        return resolvedIndices
    }

    private static func axisMarkers(
        for points: [MessageActivityCardPoint],
        indices: [Int],
        locale: Locale,
        calendar: Calendar)
        -> [TokenChartAxisMarker]
    {
        guard !points.isEmpty else { return [] }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("M/d")

        return indices.map { index in
            let point = points[index]
            let normalizedX = CGFloat(index) / CGFloat(max(points.count - 1, 1))
            let priority: TokenChartAxisMarker.Priority = if index == 0 || index == points.count - 1 {
                .boundary
            } else {
                .normal
            }

            return TokenChartAxisMarker(
                id: point.id,
                text: formatter.string(from: point.date),
                normalizedX: normalizedX,
                priority: priority)
        }
    }

    private static func peakPointID(for points: [MessageActivityCardPoint]) -> String? {
        guard let peakPoint = points.max(by: isOrderedAscending),
              peakPoint.stats.instructionCount > 0 else { return nil }
        return peakPoint.id
    }

    private static func isOrderedAscending(_ lhs: MessageActivityCardPoint, _ rhs: MessageActivityCardPoint) -> Bool {
        if lhs.stats.instructionCount == rhs.stats.instructionCount {
            return lhs.date < rhs.date
        }
        return lhs.stats.instructionCount < rhs.stats.instructionCount
    }
}

struct MessageActivityCardView: View {
    enum RenderMode: Equatable {
        case shell
        case chart
    }

    let days: [DailyOutboundMessageStats]
    let todayTotal: DailyOutboundMessageStats
    let sevenDayTotal: DailyOutboundMessageStats
    let thirtyDayTotal: DailyOutboundMessageStats
    let cumulativeTotal: DailyOutboundMessageStats
    let strings: AppStrings
    let usesFloatingStyle: Bool
    let renderMode: RenderMode
    private let model: MessageActivityCardModel

    init(
        days: [DailyOutboundMessageStats],
        todayTotal: DailyOutboundMessageStats,
        sevenDayTotal: DailyOutboundMessageStats,
        thirtyDayTotal: DailyOutboundMessageStats,
        cumulativeTotal: DailyOutboundMessageStats,
        strings: AppStrings,
        usesFloatingStyle: Bool,
        renderMode: RenderMode = .chart)
    {
        self.days = days
        self.todayTotal = todayTotal
        self.sevenDayTotal = sevenDayTotal
        self.thirtyDayTotal = thirtyDayTotal
        self.cumulativeTotal = cumulativeTotal
        self.strings = strings
        self.usesFloatingStyle = usesFloatingStyle
        self.renderMode = renderMode
        self.model = MessageActivityCardModelBuilder.makeModel(
            days: self.days,
            todayTotal: self.todayTotal,
            sevenDayTotal: self.sevenDayTotal,
            thirtyDayTotal: self.thirtyDayTotal,
            cumulativeTotal: self.cumulativeTotal,
            locale: self.strings.locale)
    }

    private var secondaryText: Color {
        self.usesFloatingStyle ? TokenFloatingCardTheme.secondaryText : TokenMenuTheme.secondaryText
    }

    private var tertiaryText: Color {
        self.usesFloatingStyle ? TokenFloatingCardTheme.tertiaryText : TokenMenuTheme.tertiaryText
    }

    private var chartPlotHeight: CGFloat {
        max(MessageActivityCardLayoutMetrics.miniChartHeight - DashboardThirtyDayBarStyle.axisLabelReservedHeight, 1)
    }

    private var dividerTint: Color {
        self.usesFloatingStyle
            ? TokenFloatingCardTheme.stroke.opacity(0.62)
            : TokenMenuTheme.quotaDivider.opacity(0.92)
    }

    private var metricValueStyle: AnyShapeStyle {
        if self.usesFloatingStyle {
            return AnyShapeStyle(TokenFloatingCardTheme.valueGradient(for: .input))
        }
        return AnyShapeStyle(TokenMenuTheme.analyticsTint)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MessageActivityCardLayoutMetrics.rootSpacing) {
            self.metricBand

            Rectangle()
                .fill(self.dividerTint.opacity(MessageActivityCardLayoutMetrics.sectionDividerOpacity))
                .frame(height: 1)

            if self.renderMode == .chart {
                if self.model.hasData {
                    self.chartContent
                } else {
                    Text(self.strings.noMessageActivityData)
                        .font(.system(size: 12))
                        .foregroundStyle(self.tertiaryText)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: MessageActivityCardLayoutMetrics.miniChartHeight,
                            alignment: .center)
                }
            } else {
                self.chartSkeleton
            }
        }
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: MessageActivityCardLayoutMetrics.miniChartSpacing) {
            VStack(alignment: .leading, spacing: 0) {
                Chart(self.model.points) { point in
                    let displayedValue = dashboardThirtyDayDisplayedBarValue(
                        for: point.stats.instructionCount,
                        scale: self.model.scale)
                    let isPeak = self.model.peakPointID == point.id && point.stats.instructionCount > 0

                    dashboardThirtyDayBarMarks(
                        date: point.date,
                        rawValue: point.stats.instructionCount,
                        displayedValue: displayedValue,
                        isPeak: isPeak,
                        scale: self.model.scale,
                        usesFloatingLowerCards: self.usesFloatingStyle,
                        peakBubbleText: isPeak
                            ? self.strings.messageActivityPeakBubbleText(point.stats.instructionCount)
                            : nil)
                }
                .chartYScale(domain: 0...self.model.scale.topValue)
                .chartPlotStyle { plot in
                    plot
                        .padding(.top, DashboardThirtyDayBarStyle.peakLabelReservedHeight)
                }
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: self.model.scale.axisValues) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [3, 5]))
                            .foregroundStyle(
                                dashboardChartGridTint(usesFloatingLowerCards: self.usesFloatingStyle)
                                    .opacity(0.72))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: self.model.axisDates) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.35, dash: [2, 6]))
                            .foregroundStyle(
                                dashboardChartGridTint(usesFloatingLowerCards: self.usesFloatingStyle)
                                    .opacity(0.42))
                    }
                }
                .frame(height: self.chartPlotHeight)

                TokenChartBottomAxisStrip(
                    markers: self.model.axisMarkers,
                    frameHeight: DashboardThirtyDayBarStyle.axisLabelReservedHeight,
                    rowCenterY: DashboardThirtyDayBarStyle.axisLabelTopGap
                        + (DashboardThirtyDayBarStyle.axisLabelHeight / 2),
                    labelWidth: { marker in
                        dashboardThirtyDayAxisLabelWidth(for: marker.text)
                    },
                    label: { marker, alignment in
                        dashboardThirtyDayAxisLabel(
                            text: marker.text,
                            alignment: alignment,
                            usesFloatingLowerCards: self.usesFloatingStyle)
                    })
            }
            .frame(height: MessageActivityCardLayoutMetrics.miniChartHeight)
        }
    }

    private var chartSkeleton: some View {
        VStack(alignment: .leading, spacing: MessageActivityCardLayoutMetrics.miniChartSpacing) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TokenFloatingCardTheme.track.opacity(0.62))
                        .frame(height: self.chartPlotHeight)

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach([0.34, 0.48, 0.28, 0.56, 0.42, 0.64, 0.38, 0.52], id: \.self) { ratio in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(TokenFloatingCardTheme.valueColor(for: .input).opacity(0.48))
                                .frame(maxWidth: .infinity)
                                .frame(height: self.chartPlotHeight * ratio)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }

                Capsule(style: .continuous)
                    .fill(TokenFloatingCardTheme.track.opacity(0.54))
                    .frame(height: DashboardThirtyDayBarStyle.axisLabelHeight)
                    .padding(.top, DashboardThirtyDayBarStyle.axisLabelTopGap)
            }
            .frame(height: MessageActivityCardLayoutMetrics.miniChartHeight)
        }
    }

    private var metricBand: some View {
        self.metricValueColumns { column, _ in
            VStack(alignment: .leading, spacing: MessageActivityCardLayoutMetrics.metricLabelTopSpacing) {
                Text(self.countValueText(column.stats.instructionCount))
                    .font(.system(size: MessageActivityCardLayoutMetrics.metricValueFontSize, weight: .bold))
                    .foregroundStyle(self.metricValueStyle)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(column.title)
                    .font(.system(size: MessageActivityCardLayoutMetrics.metricLabelFontSize, weight: .semibold))
                    .foregroundStyle(self.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, MessageActivityCardLayoutMetrics.summaryHorizontalPadding)
        .padding(.vertical, MessageActivityCardLayoutMetrics.summaryVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricValueColumns(
        @ViewBuilder content: @escaping ((title: String, stats: DailyOutboundMessageStats), Int) -> some View)
        -> some View
    {
        HStack(alignment: .top, spacing: MessageActivityCardLayoutMetrics.matrixColumnSpacing) {
            ForEach(Array(self.metricColumns.enumerated()), id: \.element.title) { index, column in
                content(column, index)
                    .overlay(alignment: .trailing) {
                        if index < self.metricColumns.count - 1 {
                            Rectangle()
                                .fill(
                                    self.dividerTint.opacity(
                                        MessageActivityCardLayoutMetrics.columnDividerOpacity))
                                .frame(width: 1)
                                .padding(.vertical, 1)
                                .offset(x: MessageActivityCardLayoutMetrics.matrixColumnSpacing / 2)
                        }
                    }
            }
        }
    }

    private var metricColumns: [(title: String, stats: DailyOutboundMessageStats)] {
        [
            (self.strings.messageActivityTodayTitle, self.model.todayTotal),
            (self.strings.messageActivitySevenDayTitle, self.model.sevenDayTotal),
            (self.strings.messageActivityThirtyDayTitle, self.model.thirtyDayTotal),
            (self.strings.messageActivityCumulativeTitle, self.model.cumulativeTotal),
        ]
    }

    private func countValueText(_ value: Int) -> String {
        UsageStore.exactTokenText(value, locale: self.strings.locale)
    }
}
