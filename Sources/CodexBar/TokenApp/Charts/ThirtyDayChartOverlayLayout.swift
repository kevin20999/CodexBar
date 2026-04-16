import AppKit
import Charts
import SwiftUI

enum ThirtyDayChartAxisLabelResolver {
    enum TextAlignment: String, Equatable, Sendable {
        case leading
        case center
        case trailing

        var frameAlignment: Alignment {
            switch self {
            case .leading:
                .leading
            case .center:
                .center
            case .trailing:
                .trailing
            }
        }
    }

    struct Label: Equatable, Sendable {
        let id: String
        let text: String
        let centerX: CGFloat
        let width: CGFloat
    }

    struct Placement: Identifiable, Equatable, Sendable {
        let id: String
        let text: String
        let centerX: CGFloat
        let centerY: CGFloat
        let width: CGFloat
        let alignment: TextAlignment
    }

    static func resolvePlacements(
        labels: [Label],
        plotFrame: CGRect,
        rowCenterY: CGFloat)
        -> [Placement]
    {
        guard !labels.isEmpty else { return [] }

        return labels.enumerated().map { index, label in
            let isFirst = index == labels.startIndex
            let isLast = index == labels.index(before: labels.endIndex)
            let minX: CGFloat = if isFirst {
                plotFrame.minX
            } else if isLast {
                plotFrame.maxX - label.width
            } else {
                label.centerX - (label.width / 2)
            }

            let clampedMinX = min(
                max(plotFrame.minX, minX),
                max(plotFrame.maxX - label.width, plotFrame.minX))
            let alignment: TextAlignment = if isFirst {
                .leading
            } else if isLast {
                .trailing
            } else {
                .center
            }

            return Placement(
                id: label.id,
                text: label.text,
                centerX: clampedMinX + (label.width / 2),
                centerY: rowCenterY,
                width: label.width,
                alignment: alignment)
        }
    }
}

struct DashboardThirtyDayPeakLabelPlacement {
    let text: String
    let width: CGFloat
    let height: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
}

func dashboardThirtyDayPeakLabelPlacement(
    date: Date,
    rawValue: Int,
    bubbleText: String,
    scale: DashboardThirtyDayChartScale,
    proxy: ChartProxy,
    geo: GeometryProxy)
    -> DashboardThirtyDayPeakLabelPlacement?
{
    guard let plotAnchor = proxy.plotFrame else { return nil }
    guard let plotX = proxy.position(forX: date) else { return nil }

    let plotFrame = geo[plotAnchor]
    let labelWidth = dashboardThirtyDayPeakLabelWidth(for: bubbleText)
    let labelHeight = DashboardThirtyDayBarStyle.peakLabelHeight
    let labelHalfWidth = labelWidth / 2
    let labelHalfHeight = labelHeight / 2
    let minCenterX = plotFrame.minX + labelHalfWidth
    let maxCenterX = max(minCenterX, plotFrame.maxX - labelHalfWidth)
    let centerX = min(max(plotFrame.minX + plotX, minCenterX), maxCenterX)
    let preferredCenterY = dashboardThirtyDayBarTopY(
        for: rawValue,
        scale: scale,
        plotFrame: plotFrame) - DashboardThirtyDayBarStyle.peakLabelGap - labelHalfHeight
    let centerY = max(labelHalfHeight + DashboardThirtyDayBarStyle.peakLabelTopInset, preferredCenterY)

    return DashboardThirtyDayPeakLabelPlacement(
        text: bubbleText,
        width: labelWidth,
        height: labelHeight,
        centerX: centerX,
        centerY: centerY)
}

func dashboardThirtyDayAxisLabelPlacements(
    axisDates: [Date],
    proxy: ChartProxy,
    geo: GeometryProxy,
    axisLabelText: (Date) -> String)
    -> [ThirtyDayChartAxisLabelResolver.Placement]
{
    guard let plotAnchor = proxy.plotFrame else { return [] }
    let plotFrame = geo[plotAnchor]
    let rowCenterY = min(
        geo.size.height - DashboardThirtyDayBarStyle.axisLabelBottomInset
            - (DashboardThirtyDayBarStyle.axisLabelHeight / 2),
        plotFrame.maxY + DashboardThirtyDayBarStyle.axisLabelTopGap
            + (DashboardThirtyDayBarStyle.axisLabelHeight / 2))

    let labels = axisDates.compactMap { date -> ThirtyDayChartAxisLabelResolver.Label? in
        guard let plotX = proxy.position(forX: date) else { return nil }
        let text = axisLabelText(date)
        let width = dashboardThirtyDayAxisLabelWidth(for: text)
        return ThirtyDayChartAxisLabelResolver.Label(
            id: "\(Int(date.timeIntervalSince1970))",
            text: text,
            centerX: plotFrame.minX + plotX,
            width: width)
    }

    return ThirtyDayChartAxisLabelResolver.resolvePlacements(
        labels: labels,
        plotFrame: plotFrame,
        rowCenterY: rowCenterY)
}

func dashboardThirtyDayBarTopY(
    for rawValue: Int,
    scale: DashboardThirtyDayChartScale,
    plotFrame: CGRect)
    -> CGFloat
{
    let value = dashboardThirtyDayDisplayedBarValue(for: rawValue, scale: scale)
    guard scale.topValue > 0 else { return plotFrame.maxY }
    return plotFrame.maxY - (plotFrame.height * CGFloat(value / scale.topValue))
}

func dashboardThirtyDayPeakLabel(text: String) -> some View {
    Text(text)
        .font(.system(size: DashboardThirtyDayBarStyle.peakLabelFontSize, weight: .bold))
        .foregroundStyle(TokenFloatingCardTheme.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
        .padding(.horizontal, DashboardThirtyDayBarStyle.peakLabelHorizontalPadding)
        .background {
            Capsule(style: .continuous)
                .fill(TokenFloatingCardTheme.cardTop.opacity(0.94))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(TokenFloatingCardTheme.stroke.opacity(0.9), lineWidth: 0.75)
                }
        }
        .shadow(color: dashboardThirtyDayBarGlow().opacity(0.20), radius: 8, x: 0, y: 2)
}

func dashboardThirtyDayAxisLabel(
    text: String,
    alignment: ThirtyDayChartAxisLabelResolver.TextAlignment,
    usesFloatingLowerCards: Bool)
    -> some View
{
    Text(text)
        .font(.system(size: DashboardThirtyDayBarStyle.axisLabelFontSize, weight: .medium))
        .foregroundStyle(dashboardChartAxisTint(usesFloatingLowerCards: usesFloatingLowerCards))
        .lineLimit(1)
        .minimumScaleFactor(0.88)
        .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
}

func dashboardThirtyDayPeakLabelWidth(for text: String) -> CGFloat {
    let textWidth = dashboardChartTextWidth(
        text,
        font: .systemFont(ofSize: DashboardThirtyDayBarStyle.peakLabelFontSize, weight: .bold))
    let width = textWidth + (DashboardThirtyDayBarStyle.peakLabelHorizontalPadding * 2)
    return min(max(width, DashboardThirtyDayBarStyle.peakLabelMinWidth), DashboardThirtyDayBarStyle.peakLabelMaxWidth)
}

func dashboardThirtyDayAxisLabelWidth(for text: String) -> CGFloat {
    dashboardChartTextWidth(
        text,
        font: .systemFont(ofSize: DashboardThirtyDayBarStyle.axisLabelFontSize, weight: .medium))
        + (DashboardThirtyDayBarStyle.axisLabelHorizontalPadding * 2)
}

func dashboardChartTextWidth(_ text: String, font: NSFont) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    return ceil((text as NSString).size(withAttributes: attributes).width)
}
