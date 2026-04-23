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
    @State private var rocketMotion = TokenSpeedRocketBurstMotion.zero

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

                        if let placement = self.rocketHeadPlacement(proxy: proxy, geo: geo) {
                            self.rocketHead
                                .position(x: placement.x, y: placement.y)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .frame(height: self.plotHeight)
            .task(id: self.rocketBurstTrigger) {
                await self.runRocketBurstAnimation()
            }

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

    private var rocketBurstTrigger: TokenSpeedRocketBurstTrigger? {
        TokenSpeedRocketBurstTrigger(
            launchTimestamp: self.model.rocketLaunchTimestamp,
            launchStrength: self.model.rocketLaunchStrength)
    }

    private var rocketHead: some View {
        Text("🚀")
            .font(.system(size: self.rocketFontSize))
            .offset(x: self.rocketMotion.xOffset, y: self.rocketMotion.yOffset)
            .rotationEffect(.degrees(self.rocketMotion.rotation))
            .scaleEffect(self.rocketMotion.scale)
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

    @MainActor
    private func runRocketBurstAnimation() async {
        guard self.rocketBurstTrigger != nil else {
            self.rocketMotion = .zero
            return
        }

        let launchStrength = TokenSpeedRocketBurstAnimator.clampedStrength(self.model.rocketLaunchStrength)
        self.rocketMotion = .zero

        withAnimation(TokenSpeedRocketBurstAnimator.ignitionAnimation) {
            self.rocketMotion = TokenSpeedRocketBurstAnimator.launchMotion(
                strength: launchStrength,
                allowsHorizontalDrift: true)
        }

        do {
            try await Task.sleep(for: TokenSpeedRocketBurstAnimator.ignitionDuration)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        withAnimation(TokenSpeedRocketBurstAnimator.settleAnimation) {
            self.rocketMotion = TokenSpeedRocketBurstAnimator.settleMotion(
                strength: launchStrength,
                allowsHorizontalDrift: true)
        }

        do {
            try await Task.sleep(for: TokenSpeedRocketBurstAnimator.settleDuration)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        withAnimation(TokenSpeedRocketBurstAnimator.returnAnimation) {
            self.rocketMotion = .zero
        }
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
