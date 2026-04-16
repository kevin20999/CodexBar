import Charts
import SwiftUI

private struct TokenSpeedVerticalGridPlacement: Identifiable, Equatable {
    let id: String
    let text: String
    let progress: CGFloat
    let alignment: ThirtyDayChartAxisLabelResolver.TextAlignment
    let width: CGFloat
}

struct TokenSpeedThroughputChartView: View {
    let model: TokenSpeedPanelModel
    let strings: AppStrings
    let lineTint: Color
    let plotHeight: CGFloat
    let axisRowHeight: CGFloat
    let showsAxisRow: Bool
    let plotTopPadding: CGFloat
    let lineWidth: CGFloat
    let horizontalGridOpacity: Double
    let verticalGridOpacity: Double
    let rocketFontSize: CGFloat
    let rocketTopOffset: CGFloat

    init(
        model: TokenSpeedPanelModel,
        strings: AppStrings,
        lineTint: Color,
        plotHeight: CGFloat,
        axisRowHeight: CGFloat,
        showsAxisRow: Bool = true,
        plotTopPadding: CGFloat = 16,
        lineWidth: CGFloat = 2.2,
        horizontalGridOpacity: Double = 0.72,
        verticalGridOpacity: Double = 0.42,
        rocketFontSize: CGFloat = 14,
        rocketTopOffset: CGFloat = 9)
    {
        self.model = model
        self.strings = strings
        self.lineTint = lineTint
        self.plotHeight = plotHeight
        self.axisRowHeight = axisRowHeight
        self.showsAxisRow = showsAxisRow
        self.plotTopPadding = plotTopPadding
        self.lineWidth = lineWidth
        self.horizontalGridOpacity = horizontalGridOpacity
        self.verticalGridOpacity = verticalGridOpacity
        self.rocketFontSize = rocketFontSize
        self.rocketTopOffset = rocketTopOffset
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Chart {
                ForEach(self.model.points) { point in
                    LineMark(
                        x: .value("Second", point.timestamp),
                        y: .value("Activity", point.displayValue))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(self.lineTint)
                        .lineStyle(StrokeStyle(lineWidth: self.lineWidth, lineCap: .round, lineJoin: .round))
                }
            }
            .chartYScale(domain: 0...self.model.scaleTopValue)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: self.chartYAxisValues) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [3, 5]))
                        .foregroundStyle(
                            dashboardChartGridTint(usesFloatingLowerCards: true)
                                .opacity(self.horizontalGridOpacity))
                }
            }
            .chartXAxis(.hidden)
            .chartPlotStyle { plot in
                plot.padding(.top, self.plotTopPadding)
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        ForEach(self.axisPlacements) { placement in
                            Path { path in
                                let x = self.axisGridX(for: placement, in: proxy, geo: geo)
                                guard let x else { return }
                                guard let plotAnchor = proxy.plotFrame else { return }
                                let plotFrame = geo[plotAnchor]
                                path.move(to: CGPoint(x: x, y: plotFrame.minY))
                                path.addLine(to: CGPoint(x: x, y: plotFrame.maxY))
                            }
                            .stroke(
                                dashboardChartGridTint(usesFloatingLowerCards: true)
                                    .opacity(self.verticalGridOpacity),
                                style: StrokeStyle(lineWidth: 0.35, dash: [2, 6]))
                            .allowsHitTesting(false)
                        }

                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                            if let placement = self.rocketHeadPlacement(proxy: proxy, geo: geo) {
                                self.rocketHead(at: context.date)
                                    .position(x: placement.x, y: placement.y)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .frame(height: self.plotHeight)

            if self.showsAxisRow {
                self.chartAxisRow
            }
        }
    }

    private var chartYAxisValues: [Double] {
        if self.model.scaleTopValue <= 1 {
            return [0, 0.5, 1]
        }
        return [0, self.model.scaleTopValue / 2, self.model.scaleTopValue]
    }

    @ViewBuilder
    private func rocketHead(at date: Date) -> some View {
        let motion = self.rocketMotion(at: date)
        Text("🚀")
            .font(.system(size: self.rocketFontSize))
            .offset(x: motion.xOffset, y: motion.yOffset)
            .rotationEffect(.degrees(motion.rotation))
            .scaleEffect(motion.scale)
            .animation(.smooth(duration: 0.9), value: self.model.rocketHeadPoint)
    }

    private var axisPlacements: [TokenSpeedVerticalGridPlacement] {
        let axisDates = self.model.axisDates
        guard !axisDates.isEmpty else { return [] }

        let denominator = max(axisDates.count - 1, 1)
        return axisDates.enumerated().map { index, date in
            let text = self.chartAxisText(for: date)
            return TokenSpeedVerticalGridPlacement(
                id: "\(Int(date.timeIntervalSince1970))",
                text: text,
                progress: CGFloat(index) / CGFloat(denominator),
                alignment: self.axisAlignment(index: index, count: axisDates.count),
                width: dashboardThirtyDayAxisLabelWidth(for: text))
        }
    }

    private func axisAlignment(
        index: Int,
        count: Int)
        -> ThirtyDayChartAxisLabelResolver.TextAlignment
    {
        switch (count, index) {
        case (1, _):
            .center
        case (_, 0):
            .leading
        case let (value, current) where current == value - 1:
            .trailing
        default:
            .center
        }
    }

    private var chartAxisRow: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(self.axisPlacements) { placement in
                    dashboardThirtyDayAxisLabel(
                        text: placement.text,
                        alignment: placement.alignment,
                        usesFloatingLowerCards: true)
                        .frame(
                            width: placement.width,
                            height: self.axisRowHeight,
                            alignment: placement.alignment.frameAlignment)
                        .position(
                            x: self.axisLabelCenterX(for: placement, availableWidth: geo.size.width),
                            y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: self.axisRowHeight)
    }

    private func axisGridX(
        for placement: TokenSpeedVerticalGridPlacement,
        in proxy: ChartProxy,
        geo: GeometryProxy)
        -> CGFloat?
    {
        guard let plotAnchor = proxy.plotFrame else { return nil }
        let plotFrame = geo[plotAnchor]
        return plotFrame.minX + (plotFrame.width * placement.progress)
    }

    private func axisLabelCenterX(
        for placement: TokenSpeedVerticalGridPlacement,
        availableWidth: CGFloat)
        -> CGFloat
    {
        switch placement.alignment {
        case .leading:
            return placement.width / 2
        case .trailing:
            return max(placement.width / 2, availableWidth - (placement.width / 2))
        case .center:
            if self.axisPlacements.count == 1 {
                return availableWidth / 2
            }
            return availableWidth * placement.progress
        }
    }

    private func rocketHeadPlacement(proxy: ChartProxy, geo: GeometryProxy) -> CGPoint? {
        guard let plotAnchor = proxy.plotFrame else { return nil }
        guard let plotX = proxy.position(forX: self.model.rocketHeadPoint.timestamp) else { return nil }

        let plotFrame = geo[plotAnchor]
        let x = plotFrame.minX + plotX
        let y = self.rocketTrackY(
            for: self.model.rocketHeadPoint.rocketValue,
            plotFrame: plotFrame) - self.rocketTopOffset
        return CGPoint(x: x, y: y)
    }

    private func rocketTrackY(for value: Double, plotFrame: CGRect) -> CGFloat {
        guard self.model.scaleTopValue > 0 else { return plotFrame.maxY }
        return plotFrame.maxY - (plotFrame.height * CGFloat(value / self.model.scaleTopValue))
    }

    private func rocketMotion(at date: Date) -> TokenSpeedThroughputRocketMotion {
        guard let launchDate = self.model.rocketLaunchTimestamp,
              self.model.rocketLaunchStrength > 0
        else {
            return .zero
        }

        let elapsed = max(0, date.timeIntervalSince(launchDate))
        let envelope = CGFloat(exp(-4.1 * elapsed))
        let launchStrength = CGFloat(self.model.rocketLaunchStrength)

        return TokenSpeedThroughputRocketMotion(
            xOffset: CGFloat(sin(elapsed * 46)) * launchStrength * 2.6 * envelope,
            yOffset: (-launchStrength * 6.2 * envelope)
                + (CGFloat(cos(elapsed * 52)) * launchStrength * 1.7 * envelope),
            rotation: Double(sin(elapsed * 42)) * Double(launchStrength * 8 * envelope),
            scale: 1 + (launchStrength * 0.08 * envelope))
    }

    private func chartAxisText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = self.strings.locale
        formatter.calendar = Calendar.current
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

private struct TokenSpeedThroughputRocketMotion: Equatable {
    let xOffset: CGFloat
    let yOffset: CGFloat
    let rotation: Double
    let scale: CGFloat

    static let zero = TokenSpeedThroughputRocketMotion(
        xOffset: 0,
        yOffset: 0,
        rotation: 0,
        scale: 1)
}
