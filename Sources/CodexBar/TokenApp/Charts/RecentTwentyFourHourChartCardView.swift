import AppKit
import Charts
import CodexBarCore
import SwiftUI

struct RecentTwentyFourHourChartPoint: Identifiable, Equatable {
    let slotIndex: Int
    let xValue: Double
    let hourStart: Date
    let totalTokens: Int
    let compressedHourEnd: Date?
    let labelStartHour: Date?
    let labelEndHour: Date?

    var id: Int {
        self.slotIndex
    }

    var slotValue: Double {
        self.xValue
    }

    var isCompressedRange: Bool {
        self.compressedHourEnd != nil
    }
}

struct RecentTwentyFourHourChartAxisMarker: Equatable {
    enum Priority: Int, Equatable {
        case normal
        case compressed
        case boundary
    }

    let slotValue: Double
    let text: String
    let priority: Priority
}

struct RecentTwentyFourHourChartModel: Equatable {
    let points: [RecentTwentyFourHourChartPoint]
    let axisMarkers: [RecentTwentyFourHourChartAxisMarker]
    let xAxisTickValues: [Double]
    let peakPoint: RecentTwentyFourHourChartPoint?
    let latestPoint: RecentTwentyFourHourChartPoint?
    let totalTokens: Int

    var hasData: Bool {
        self.points.contains { $0.totalTokens > 0 }
    }

    var xDomainUpperBound: Double {
        max(self.points.last?.slotValue ?? 0, 1)
    }

    var showsSeparatePeakPoint: Bool {
        guard let peakPoint = self.peakPoint, let latestPoint = self.latestPoint else {
            return false
        }
        return peakPoint.id != latestPoint.id
    }
}

enum RecentTwentyFourHourChartModelBuilder {
    static let displayedHourCount = 48
    static let minimumCompressedZeroRunLength = 4
    static let compressedRangeVisualWidth = 2.0

    static func makeModel(
        from hours: [HourlyTokenStats],
        calendar: Calendar = .current)
        -> RecentTwentyFourHourChartModel
    {
        let displayHours = Self.normalizedHours(from: hours, calendar: calendar)
        let points = Self.compressedPoints(from: displayHours)

        let peakPoint = points.max { lhs, rhs in
            if lhs.totalTokens == rhs.totalTokens {
                return lhs.slotIndex < rhs.slotIndex
            }
            return lhs.totalTokens < rhs.totalTokens
        }

        let resolvedPeakPoint: RecentTwentyFourHourChartPoint? = if let peakPoint, peakPoint.totalTokens > 0 {
            peakPoint
        } else {
            nil
        }

        return RecentTwentyFourHourChartModel(
            points: points,
            axisMarkers: Self.axisMarkers(for: points, calendar: calendar),
            xAxisTickValues: Self.xAxisTickValues(for: points),
            peakPoint: resolvedPeakPoint,
            latestPoint: points.last,
            totalTokens: displayHours.reduce(0) { $0 + $1.totalTokens })
    }

    private static func normalizedHours(
        from hours: [HourlyTokenStats],
        calendar: Calendar)
        -> [HourlyTokenStats]
    {
        let sortedHours = Array(
            hours
                .sorted { $0.hourStart < $1.hourStart }
                .suffix(Self.displayedHourCount))
        guard let latestHourStart = sortedHours.last?.hourStart else { return [] }

        let knownHours = Dictionary(
            uniqueKeysWithValues: sortedHours.map { (Int($0.hourStart.timeIntervalSince1970), $0) })

        return (0..<Self.displayedHourCount).compactMap { offset in
            let hourOffset = offset - (Self.displayedHourCount - 1)
            guard let hourStart = calendar.date(byAdding: .hour, value: hourOffset, to: latestHourStart) else {
                return nil
            }
            let key = Int(hourStart.timeIntervalSince1970)
            return knownHours[key] ?? .empty(for: hourStart)
        }
    }

    private static func compressedPoints(from hours: [HourlyTokenStats]) -> [RecentTwentyFourHourChartPoint] {
        var points: [RecentTwentyFourHourChartPoint] = []
        var rawIndex = 0
        var slotIndex = 0
        var xValue = 0.0

        while rawIndex < hours.count {
            let hour = hours[rawIndex]

            if hour.totalTokens == 0 {
                var zeroRunEnd = rawIndex
                while zeroRunEnd < hours.count, hours[zeroRunEnd].totalTokens == 0 {
                    zeroRunEnd += 1
                }

                let shouldCompress = rawIndex > 0
                    && zeroRunEnd < hours.count
                    && (zeroRunEnd - rawIndex) >= Self.minimumCompressedZeroRunLength

                if shouldCompress {
                    points.append(
                        RecentTwentyFourHourChartPoint(
                            slotIndex: slotIndex,
                            xValue: xValue + ((Self.compressedRangeVisualWidth - 1.0) / 2.0),
                            hourStart: hour.hourStart,
                            totalTokens: 0,
                            compressedHourEnd: hours[zeroRunEnd - 1].hourStart,
                            labelStartHour: hours[rawIndex - 1].hourStart,
                            labelEndHour: hours[zeroRunEnd].hourStart))
                    rawIndex = zeroRunEnd
                    slotIndex += 1
                    xValue += Self.compressedRangeVisualWidth
                    continue
                }

                for zeroIndex in rawIndex..<zeroRunEnd {
                    points.append(
                        RecentTwentyFourHourChartPoint(
                            slotIndex: slotIndex,
                            xValue: xValue,
                            hourStart: hours[zeroIndex].hourStart,
                            totalTokens: 0,
                            compressedHourEnd: nil,
                            labelStartHour: nil,
                            labelEndHour: nil))
                    slotIndex += 1
                    xValue += 1
                }
                rawIndex = zeroRunEnd
                continue
            }

            points.append(
                RecentTwentyFourHourChartPoint(
                    slotIndex: slotIndex,
                    xValue: xValue,
                    hourStart: hour.hourStart,
                    totalTokens: hour.totalTokens,
                    compressedHourEnd: nil,
                    labelStartHour: nil,
                    labelEndHour: nil))
            rawIndex += 1
            slotIndex += 1
            xValue += 1
        }

        return points
    }

    static func axisMarkers(
        for points: [RecentTwentyFourHourChartPoint],
        calendar: Calendar)
        -> [RecentTwentyFourHourChartAxisMarker]
    {
        guard let firstSlotIndex = points.first?.slotIndex, let lastSlotIndex = points.last?.slotIndex else {
            return []
        }

        return points.map { point in
            let priority: RecentTwentyFourHourChartAxisMarker.Priority = if point.slotIndex == firstSlotIndex
                || point.slotIndex == lastSlotIndex
            {
                .boundary
            } else if point.isCompressedRange {
                .compressed
            } else {
                .normal
            }

            return RecentTwentyFourHourChartAxisMarker(
                slotValue: point.slotValue,
                text: Self.axisText(for: point, calendar: calendar),
                priority: priority)
        }
    }

    private static func axisText(for point: RecentTwentyFourHourChartPoint, calendar: Calendar) -> String {
        if let labelStartHour = point.labelStartHour, let labelEndHour = point.labelEndHour {
            let startHour = String(calendar.component(.hour, from: labelStartHour))
            let endHour = String(calendar.component(.hour, from: labelEndHour))
            return "\(startHour)～\(endHour)"
        }

        let startHour = String(calendar.component(.hour, from: point.hourStart))
        guard let compressedHourEnd = point.compressedHourEnd else { return startHour }
        let endHour = String(calendar.component(.hour, from: compressedHourEnd))
        return "\(startHour)～\(endHour)"
    }

    private static func xAxisTickValues(for points: [RecentTwentyFourHourChartPoint]) -> [Double] {
        guard let lastXValue = points.last?.slotValue else { return [] }
        let upperBound = max(lastXValue, 1)
        let step = max(1.0, round(upperBound / 6.0))
        var values: Set<Double> = [0, upperBound]
        var tickValue = 0.0

        while tickValue <= upperBound {
            values.insert(tickValue)
            tickValue += step
        }

        for point in points where point.isCompressedRange {
            values.insert(point.slotValue)
        }

        return values.sorted()
    }
}

@MainActor
struct RecentTwentyFourHourChartCardView: View {
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
        static let supportLineWidth: CGFloat = 21.0
        static let lineWidth: CGFloat = 9.5
        static let highlightLineWidth: CGFloat = 2.8
        static let peakPointHaloSize: CGFloat = 64
        static let peakPointSize: CGFloat = 22
        static let peakPointGlowRadius: CGFloat = 6
        static let latestPointHaloSize: CGFloat = 240
        static let latestPointRingSize: CGFloat = 132
        static let latestPointCoreSize: CGFloat = 60
        static let latestPointGlowRadius: CGFloat = 11
        static let peakLabelFontSize: CGFloat = 10
        static let peakLabelMinWidth: CGFloat = 42
        static let peakLabelMaxWidth: CGFloat = 58
        static let peakLabelHorizontalPadding: CGFloat = 10
        static let peakLabelHighlightHeight: CGFloat = 3
        static let peakLabelStrokeWidth: CGFloat = 0.9
        static let peakLabelHeight: CGFloat = 18
        static let peakLabelGap: CGFloat = 4
        static let peakLabelTopInset: CGFloat = 3
        static let axisLabelFontSize: CGFloat = 7.5
        static let compressedAxisLabelFontSize: CGFloat = 8.5
        static let axisLabelHeight: CGFloat = 10
        static let axisLabelTopGap: CGFloat = 1.5
        static let axisLabelBottomInset: CGFloat = 0.5
        static let axisLabelHorizontalPadding: CGFloat = 0.25

        static var peakLabelReservedHeight: CGFloat {
            self.peakLabelHeight + self.peakLabelGap + self.peakLabelTopInset
        }

        static var axisLabelReservedHeight: CGFloat {
            self.axisLabelTopGap + self.axisLabelHeight + self.axisLabelBottomInset
        }
    }

    private struct PeakLabelPlacement {
        let text: String
        let width: CGFloat
        let height: CGFloat
        let centerX: CGFloat
        let centerY: CGFloat
    }

    private struct AxisLabelCandidate {
        let id: String
        let marker: RecentTwentyFourHourChartAxisMarker
        let centerX: CGFloat
        let width: CGFloat
    }

    private let hours: [HourlyTokenStats]
    private let strings: AppStrings
    private let compact: Bool
    private let usesFloatingStyle: Bool
    private let model: RecentTwentyFourHourChartModel
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
        self.model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours)
    }

    private var secondaryText: Color {
        self.usesFloatingStyle ? TokenFloatingCardTheme.secondaryText : TokenMenuTheme.secondaryText
    }

    private var isDarkMode: Bool {
        self.colorScheme == .dark
    }

    private var ribbonPalette: TokenRecentHistoryTheme.RibbonPalette {
        TokenRecentHistoryTheme.palette(for: self.isDarkMode)
    }

    private var peakLabelSurface: TokenRecentHistoryTheme.PeakLabelSurface {
        self.isDarkMode ? self.ribbonPalette.peakLabelDark : self.ribbonPalette.peakLabelLight
    }

    private var peakPointColor: Color {
        self.ribbonPalette.peakPoint
    }

    private var peakGlowColor: Color {
        self.ribbonPalette.peakGlow
    }

    private var latestPointCoreColor: Color {
        self.ribbonPalette.latestCore
    }

    private var latestPointRingColor: Color {
        self.ribbonPalette.latestRing
    }

    private var latestPointGlowColor: Color {
        self.ribbonPalette.latestGlow
    }

    private var supportLineStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    self.ribbonPalette.glowStart,
                    self.ribbonPalette.glowMid,
                    self.ribbonPalette.glowEnd,
                ],
                startPoint: .leading,
                endPoint: .trailing))
    }

    private var supportLineWidth: CGFloat {
        self.isDarkMode ? 16.0 : Style.supportLineWidth
    }

    private var lineStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    self.ribbonPalette.outlineStart,
                    self.ribbonPalette.outlineMid,
                    self.ribbonPalette.outlineEnd,
                ],
                startPoint: .leading,
                endPoint: .trailing))
    }

    private var highlightLineStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    self.ribbonPalette.outlineSheen.opacity(self.isDarkMode ? 0.58 : 0.56),
                    self.ribbonPalette.outlineSheen.opacity(self.isDarkMode ? 0.10 : 0.06),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
    }

    private var highlightLineWidth: CGFloat {
        Style.highlightLineWidth
    }

    private var axisTint: Color {
        self.ribbonPalette.axis
    }

    private var boundaryAxisTint: Color {
        self.ribbonPalette.boundaryAxis
    }

    private var compressedAxisTint: Color {
        self.ribbonPalette.compressedAxis
    }

    private var gridTint: Color {
        self.ribbonPalette.grid
    }

    private var areaFillColor: Color {
        self.ribbonPalette.areaFill
    }

    private var yGridOpacity: Double {
        self.isDarkMode ? 0.22 : 0.32
    }

    private var xGridOpacity: Double {
        self.isDarkMode ? 0.12 : 0.16
    }

    private var axisTickOpacity: Double {
        self.isDarkMode ? 0.18 : 0.18
    }

    private var latestPointHaloSize: CGFloat {
        self.isDarkMode ? 188 : Style.latestPointHaloSize
    }

    private var latestPointRingSize: CGFloat {
        self.isDarkMode ? 120 : Style.latestPointRingSize
    }

    private var latestPointCoreSize: CGFloat {
        self.isDarkMode ? 52 : Style.latestPointCoreSize
    }

    private var chartHeight: CGFloat {
        self.compact ? Style.compactChartHeight : Style.regularChartHeight
    }

    var body: some View {
        let scale = Self.scale(for: self.model)
        let axisLabelPriorities = Dictionary(
            uniqueKeysWithValues: self.model.axisMarkers.map { marker in
                ("\(marker.slotValue)-\(marker.text)", marker.priority)
            })

        VStack(alignment: .leading, spacing: self.compact ? 6 : 8) {
            if self.model.hasData {
                Chart(self.model.points) { point in
                    AreaMark(
                        x: .value("Hour slot area", point.slotValue),
                        y: .value("Tokens area", Double(point.totalTokens)))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(self.areaFillColor)

                    LineMark(
                        x: .value("Hour slot support", point.slotValue),
                        y: .value("Tokens support", Double(point.totalTokens)))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(self.supportLineStyle)
                        .lineStyle(
                            StrokeStyle(
                                lineWidth: self.supportLineWidth,
                                lineCap: .round,
                                lineJoin: .round))

                    LineMark(
                        x: .value("Hour slot", point.slotValue),
                        y: .value("Tokens", Double(point.totalTokens)))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(self.lineStyle)
                        .lineStyle(
                            StrokeStyle(
                                lineWidth: Style.lineWidth,
                                lineCap: .round,
                                lineJoin: .round))

                    LineMark(
                        x: .value("Hour slot highlight", point.slotValue),
                        y: .value("Tokens highlight", Double(point.totalTokens)))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(self.highlightLineStyle)
                        .lineStyle(
                            StrokeStyle(
                                lineWidth: self.highlightLineWidth,
                                lineCap: .round,
                                lineJoin: .round))

                    if self.model.showsSeparatePeakPoint,
                       point.id == self.model.peakPoint?.id
                    {
                        PointMark(
                            x: .value("Peak hour slot halo", point.slotValue),
                            y: .value("Peak tokens halo", Double(point.totalTokens)))
                            .foregroundStyle(self.peakGlowColor)
                            .symbolSize(Style.peakPointHaloSize)

                        PointMark(
                            x: .value("Peak hour slot", point.slotValue),
                            y: .value("Peak tokens", Double(point.totalTokens)))
                            .foregroundStyle(self.peakPointColor.opacity(self.isDarkMode ? 0.94 : 0.98))
                            .symbolSize(Style.peakPointSize)
                            .shadow(
                                color: self.peakGlowColor.opacity(self.isDarkMode ? 0.58 : 0.74),
                                radius: Style.peakPointGlowRadius,
                                x: 0,
                                y: 1)
                    }

                    if point.id == self.model.latestPoint?.id {
                        PointMark(
                            x: .value("Latest hour slot halo", point.slotValue),
                            y: .value("Latest tokens halo", Double(point.totalTokens)))
                            .foregroundStyle(self.latestPointGlowColor.opacity(self.isDarkMode ? 0.88 : 1))
                            .symbolSize(self.latestPointHaloSize)

                        PointMark(
                            x: .value("Latest hour slot ring", point.slotValue),
                            y: .value("Latest tokens ring", Double(point.totalTokens)))
                            .foregroundStyle(self.latestPointRingColor.opacity(self.isDarkMode ? 0.98 : 1))
                            .symbolSize(self.latestPointRingSize)
                            .shadow(
                                color: self.latestPointGlowColor.opacity(self.isDarkMode ? 0.56 : 0.66),
                                radius: Style.latestPointGlowRadius,
                                x: 0,
                                y: 1)

                        PointMark(
                            x: .value("Latest hour slot", point.slotValue),
                            y: .value("Latest tokens", Double(point.totalTokens)))
                            .foregroundStyle(self.latestPointCoreColor.opacity(self.isDarkMode ? 0.98 : 1))
                            .symbolSize(self.latestPointCoreSize)
                            .shadow(
                                color: self.latestPointGlowColor.opacity(self.isDarkMode ? 0.34 : 0.42),
                                radius: Style.latestPointGlowRadius,
                                x: 0,
                                y: 1)
                    }
                }
                .chartXScale(
                    domain: 0.0...self.model.xDomainUpperBound)
                .chartYScale(domain: 0...scale.topValue)
                .chartPlotStyle { plot in
                    plot
                        .padding(.top, Style.peakLabelReservedHeight)
                        .padding(.bottom, Style.axisLabelReservedHeight)
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            if let placement = self.peakLabelPlacement(
                                model: self.model,
                                scale: scale,
                                proxy: proxy,
                                geo: geo)
                            {
                                self.peakLabel(text: placement.text)
                                    .frame(width: placement.width, height: placement.height)
                                    .position(x: placement.centerX, y: placement.centerY)
                                    .allowsHitTesting(false)
                            }

                            ForEach(self.axisLabelPlacements(model: self.model, proxy: proxy, geo: geo)) { placement in
                                self.axisLabel(
                                    text: placement.text,
                                    alignment: placement.alignment,
                                    priority: axisLabelPriorities[placement.id] ?? .normal)
                                    .frame(
                                        width: placement.width,
                                        height: Style.axisLabelHeight,
                                        alignment: placement.alignment.frameAlignment)
                                    .position(x: placement.centerX, y: placement.centerY)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: scale.axisValues) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [3, 5]))
                            .foregroundStyle(self.gridTint.opacity(self.yGridOpacity))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: self.model.xAxisTickValues) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.35, dash: [2, 6]))
                            .foregroundStyle(self.gridTint.opacity(self.xGridOpacity))
                        AxisTick()
                            .foregroundStyle(self.boundaryAxisTint.opacity(self.axisTickOpacity))
                    }
                }
                .chartLegend(.hidden)
                .frame(height: self.chartHeight)
            } else {
                Text(self.strings.noRecentFortyEightHourData)
                    .font(self.compact ? .caption : .footnote)
                    .foregroundStyle(self.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func scale(for model: RecentTwentyFourHourChartModel) -> Scale {
        let peakValue = max(model.peakPoint?.totalTokens ?? 0, 1)
        let topValue = max(2.0, ceil(Double(peakValue) / 0.96))
        return Scale(topValue: topValue, midpointValue: topValue / 2)
    }

    private func peakLabelPlacement(
        model: RecentTwentyFourHourChartModel,
        scale: Scale,
        proxy: ChartProxy,
        geo: GeometryProxy)
        -> PeakLabelPlacement?
    {
        guard let plotAnchor = proxy.plotFrame else { return nil }
        guard let peakPoint = model.peakPoint else { return nil }
        guard let plotX = proxy.position(forX: peakPoint.slotValue) else { return nil }

        let plotFrame = geo[plotAnchor]
        let text = self.strings.recentTwentyFourHourPeakBubbleText(peakPoint.totalTokens)
        let labelWidth = self.peakLabelWidth(for: text)
        let labelHeight = Style.peakLabelHeight
        let labelHalfWidth = labelWidth / 2
        let labelHalfHeight = labelHeight / 2
        let minCenterX = plotFrame.minX + labelHalfWidth
        let maxCenterX = max(minCenterX, plotFrame.maxX - labelHalfWidth)
        let centerX = min(max(plotFrame.minX + plotX, minCenterX), maxCenterX)
        let preferredCenterY = self.lineY(
            for: peakPoint.totalTokens,
            scale: scale,
            plotFrame: plotFrame) - Style.peakLabelGap - labelHalfHeight
        let centerY = max(labelHalfHeight + Style.peakLabelTopInset, preferredCenterY)

        return PeakLabelPlacement(
            text: text,
            width: labelWidth,
            height: labelHeight,
            centerX: centerX,
            centerY: centerY)
    }

    private func axisLabelPlacements(
        model: RecentTwentyFourHourChartModel,
        proxy: ChartProxy,
        geo: GeometryProxy)
        -> [ThirtyDayChartAxisLabelResolver.Placement]
    {
        guard let plotAnchor = proxy.plotFrame else { return [] }
        let plotFrame = geo[plotAnchor]
        let rowCenterY = min(
            geo.size.height - Style.axisLabelBottomInset - (Style.axisLabelHeight / 2),
            plotFrame.maxY + Style.axisLabelTopGap + (Style.axisLabelHeight / 2))

        let candidates = model.axisMarkers.compactMap { marker -> AxisLabelCandidate? in
            guard let plotX = proxy.position(forX: marker.slotValue) else { return nil }
            return AxisLabelCandidate(
                id: "\(marker.slotValue)-\(marker.text)",
                marker: marker,
                centerX: plotFrame.minX + plotX,
                width: self.axisLabelWidth(for: marker.text, priority: marker.priority))
        }

        let selectedCandidates = self.selectedAxisLabelCandidates(candidates, model: model, plotFrame: plotFrame)

        return selectedCandidates.map { candidate in
            let range = self.axisLabelRange(candidate: candidate, model: model, plotFrame: plotFrame)
            let alignment = self.axisLabelAlignment(for: candidate.marker.slotValue, model: model)
            return ThirtyDayChartAxisLabelResolver.Placement(
                id: candidate.id,
                text: candidate.marker.text,
                centerX: (range.lowerBound + range.upperBound) / 2,
                centerY: rowCenterY,
                width: candidate.width,
                alignment: alignment)
        }
    }

    private func selectedAxisLabelCandidates(
        _ candidates: [AxisLabelCandidate],
        model: RecentTwentyFourHourChartModel,
        plotFrame: CGRect)
        -> [AxisLabelCandidate]
    {
        guard !candidates.isEmpty else { return [] }

        let orderedCandidates = candidates.sorted { lhs, rhs in
            lhs.marker.slotValue < rhs.marker.slotValue
        }
        let firstSlotValue = model.points.first?.slotValue
        let lastSlotValue = model.points.last?.slotValue
        var selected: [AxisLabelCandidate] = []

        if let firstSlotValue,
           let firstCandidate = orderedCandidates.first(where: { $0.marker.slotValue == firstSlotValue })
        {
            selected.append(firstCandidate)
        }

        if let lastSlotValue,
           let lastCandidate = orderedCandidates.first(where: { $0.marker.slotValue == lastSlotValue }),
           selected.contains(where: { $0.id == lastCandidate.id }) == false
        {
            selected.append(lastCandidate)
        }

        let compressedCandidates = orderedCandidates.filter { $0.marker.priority == .compressed }
        for candidate in compressedCandidates
            where self.canPlaceAxisLabel(candidate, among: selected, model: model, plotFrame: plotFrame)
        {
            selected.append(candidate)
        }

        let normalCandidates = orderedCandidates.filter { $0.marker.priority == .normal }
        for candidate in normalCandidates
            where self.canPlaceAxisLabel(candidate, among: selected, model: model, plotFrame: plotFrame)
        {
            selected.append(candidate)
        }

        return selected.sorted { lhs, rhs in
            lhs.marker.slotValue < rhs.marker.slotValue
        }
    }

    private func canPlaceAxisLabel(
        _ candidate: AxisLabelCandidate,
        among selected: [AxisLabelCandidate],
        model: RecentTwentyFourHourChartModel,
        plotFrame: CGRect)
        -> Bool
    {
        let candidateRange = self.axisLabelRange(candidate: candidate, model: model, plotFrame: plotFrame)
        return selected.allSatisfy { existing in
            let existingRange = self.axisLabelRange(candidate: existing, model: model, plotFrame: plotFrame)
            return candidateRange.upperBound <= existingRange.lowerBound
                || existingRange.upperBound <= candidateRange.lowerBound
        }
    }

    private func axisLabelRange(
        candidate: AxisLabelCandidate,
        model: RecentTwentyFourHourChartModel,
        plotFrame: CGRect)
        -> ClosedRange<CGFloat>
    {
        let alignment = self.axisLabelAlignment(for: candidate.marker.slotValue, model: model)
        let minX: CGFloat = switch alignment {
        case .leading:
            plotFrame.minX
        case .trailing:
            plotFrame.maxX - candidate.width
        case .center:
            candidate.centerX - (candidate.width / 2)
        }

        let clampedMinX = min(
            max(plotFrame.minX, minX),
            max(plotFrame.maxX - candidate.width, plotFrame.minX))
        return clampedMinX...(clampedMinX + candidate.width)
    }

    private func axisLabelAlignment(
        for slotValue: Double,
        model: RecentTwentyFourHourChartModel)
        -> ThirtyDayChartAxisLabelResolver.TextAlignment
    {
        if slotValue == model.points.first?.slotValue {
            return .leading
        }
        if slotValue == model.points.last?.slotValue {
            return .trailing
        }
        return .center
    }

    private func lineY(for value: Int, scale: Scale, plotFrame: CGRect) -> CGFloat {
        guard scale.topValue > 0 else { return plotFrame.maxY }
        return plotFrame.maxY - (plotFrame.height * CGFloat(Double(value) / scale.topValue))
    }

    private func peakLabel(text: String) -> some View {
        Text(text)
            .font(.system(size: Style.peakLabelFontSize, weight: .bold))
            .foregroundStyle(self.peakLabelSurface.text)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, Style.peakLabelHorizontalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                self.peakLabelSurface.top,
                                self.peakLabelSurface.bottom,
                            ],
                            startPoint: .top,
                            endPoint: .bottom))
                    .overlay(alignment: .top) {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(self.isDarkMode ? 0.28 : 0.28),
                                        Color.clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom))
                            .frame(height: Style.peakLabelHighlightHeight)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(
                                self.peakLabelSurface.stroke,
                                lineWidth: Style.peakLabelStrokeWidth)
                    }
            }
            .shadow(color: self.peakGlowColor.opacity(self.isDarkMode ? 0.24 : 0.12), radius: 6, x: 0, y: 2)
    }

    private func axisLabel(
        text: String,
        alignment: ThirtyDayChartAxisLabelResolver.TextAlignment,
        priority: RecentTwentyFourHourChartAxisMarker.Priority)
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

    private func peakLabelWidth(for text: String) -> CGFloat {
        let textWidth = self.textWidth(text, font: .systemFont(ofSize: Style.peakLabelFontSize, weight: .bold))
        let width = textWidth + (Style.peakLabelHorizontalPadding * 2)
        return min(max(width, Style.peakLabelMinWidth), Style.peakLabelMaxWidth)
    }

    private func axisLabelWidth(for text: String, priority: RecentTwentyFourHourChartAxisMarker.Priority) -> CGFloat {
        self.textWidth(
            text,
            font: .monospacedDigitSystemFont(
                ofSize: self.axisLabelFontSize(for: priority),
                weight: self.axisLabelMeasurementWeight(for: priority)))
            + (Style.axisLabelHorizontalPadding * 2)
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

    private func axisLabelMeasurementWeight(
        for priority: RecentTwentyFourHourChartAxisMarker.Priority)
        -> NSFont.Weight
    {
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

    private func textWidth(_ text: String, font: NSFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }
}
