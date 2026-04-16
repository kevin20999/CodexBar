import AppKit
import Charts
import SwiftUI

private enum TokenSpeedPanelLayout {
    static let width: CGFloat = 438
    static let preferredHeight: CGFloat = 404
    static let cornerRadius: CGFloat = 34
    static let cardCornerRadius: CGFloat = 16
    static let rootSpacing: CGFloat = 10
    static let panelHorizontalPadding: CGFloat = 14
    static let panelVerticalPadding: CGFloat = 12
    static let chartCardPadding: CGFloat = 12
    static let plotHeight: CGFloat = 148
    static let axisRowHeight: CGFloat = 16
    static let historyRowSpacing: CGFloat = 8
    static let historyListTopSpacing: CGFloat = 8
    static let emptyStateMinHeight: CGFloat = 120
    static let valueFontSize: CGFloat = 13
    static let timeFontSize: CGFloat = 11.5
    static let headerActionButtonSize: CGFloat = 24
    static let headerActionIconSize: CGFloat = 11
}

struct TokenSpeedDisplayPoint: Identifiable, Equatable {
    let timestamp: Date
    let rawTokens: Int
    let displayValue: Double

    var id: Date {
        self.timestamp
    }
}

struct TokenSpeedRocketPoint: Identifiable, Equatable {
    let timestamp: Date
    let rocketValue: Double

    var id: Date {
        self.timestamp
    }
}

struct TokenSpeedPanelModel: Equatable {
    let points: [TokenSpeedDisplayPoint]
    let rocketPoints: [TokenSpeedRocketPoint]
    let rocketHeadPoint: TokenSpeedRocketPoint
    let rocketLaunchStrength: Double
    let rocketLaunchTimestamp: Date?
    let axisDates: [Date]
    let scaleTopValue: Double
}

enum TokenSpeedPanelModelBuilder {
    static let axisAnchorCount = 5
    static let rocketLaunchOffset = 0.18
    static let rocketDescentStep = 0.12

    static func makeModel(samples: [TokenSpeedSample]) -> TokenSpeedPanelModel {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        let points = self.displayPoints(from: sortedSamples)
        let peakDisplayValue = points.map(\.displayValue).max() ?? 0
        let scaleTopValue = self.chartCeiling(for: peakDisplayValue)
        let rocketPoints = self.rocketPoints(from: points, scaleTopValue: scaleTopValue)
        let fallbackTimestamp = points.last?.timestamp ?? Date()
        return TokenSpeedPanelModel(
            points: points,
            rocketPoints: rocketPoints,
            rocketHeadPoint: rocketPoints.last
                ?? TokenSpeedRocketPoint(timestamp: fallbackTimestamp, rocketValue: 0),
            rocketLaunchStrength: self.rocketLaunchStrength(from: points),
            rocketLaunchTimestamp: self.rocketLaunchTimestamp(from: points),
            axisDates: self.axisDates(for: points),
            scaleTopValue: scaleTopValue)
    }

    private static func displayPoints(from samples: [TokenSpeedSample]) -> [TokenSpeedDisplayPoint] {
        samples.map { sample in
            TokenSpeedDisplayPoint(
                timestamp: sample.timestamp,
                rawTokens: sample.tokens,
                displayValue: log10(Double(sample.tokens) + 1))
        }
    }

    private static func axisDates(for points: [TokenSpeedDisplayPoint]) -> [Date] {
        guard !points.isEmpty else { return [] }
        guard points.count > self.axisAnchorCount else {
            return points.map(\.timestamp)
        }

        var resolvedIndices: [Int] = []
        for anchor in 0..<self.axisAnchorCount {
            let progress = Double(anchor) / Double(max(self.axisAnchorCount - 1, 1))
            let index = Int((Double(points.count - 1) * progress).rounded())
            if resolvedIndices.last != index {
                resolvedIndices.append(index)
            }
        }
        return resolvedIndices.map { points[$0].timestamp }
    }

    private static func chartCeiling(for peakDisplayValue: Double) -> Double {
        guard peakDisplayValue > 0 else { return 1 }
        let paddedPeak = peakDisplayValue * 1.14
        return max(1, ceil(paddedPeak * 10) / 10)
    }

    private static func rocketPoints(
        from points: [TokenSpeedDisplayPoint],
        scaleTopValue: Double)
        -> [TokenSpeedRocketPoint]
    {
        var previousRocketValue = 0.0

        return points.map { point in
            let launchValue = point.rawTokens > 0
                ? min(scaleTopValue, point.displayValue + self.rocketLaunchOffset)
                : 0
            let descentValue = max(0, previousRocketValue - self.rocketDescentStep)
            let rocketValue = max(launchValue, descentValue)
            previousRocketValue = rocketValue

            return TokenSpeedRocketPoint(timestamp: point.timestamp, rocketValue: rocketValue)
        }
    }

    private static func rocketLaunchStrength(from points: [TokenSpeedDisplayPoint]) -> Double {
        guard let latestPoint = points.last else { return 0 }
        let previousTokensPerSecond = points.dropLast().last?.rawTokens ?? 0
        return MenuBarTokenSpeedMetrics.launchStrength(
            for: latestPoint.rawTokens,
            previousTokensPerSecond: previousTokensPerSecond)
    }

    private static func rocketLaunchTimestamp(from points: [TokenSpeedDisplayPoint]) -> Date? {
        guard self.rocketLaunchStrength(from: points) > 0 else { return nil }
        return points.last?.timestamp
    }
}

extension TokenSpeedPanelContent {
    private var historyList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: TokenSpeedPanelLayout.historyRowSpacing) {
                ForEach(self.store.tokenSpeedHistoryEntries) { entry in
                    self.historyRow(entry)
                }
            }
            .padding(.top, TokenSpeedPanelLayout.historyListTopSpacing)
        }
    }
}

@MainActor
struct TokenSpeedPanelContent: View {
    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore
    let panelHeight: CGFloat
    var isFloatingChartPresented = false
    var onToggleFloatingChart: () -> Void = {}
    @State private var showsFloatingChartButton = false

    static let preferredPanelWidth: CGFloat = TokenSpeedPanelLayout.width

    static func panelMetrics(availableScreenHeight: CGFloat?) -> TokenMenuPanelSizing {
        TokenMenuPanelSizing.resolve(
            naturalHeight: TokenSpeedPanelLayout.preferredHeight,
            availableScreenHeight: availableScreenHeight)
    }

    private var strings: AppStrings {
        self.settings.strings
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: TokenSpeedPanelLayout.cornerRadius, style: .continuous)
    }

    private var chartModel: TokenSpeedPanelModel {
        TokenSpeedPanelModelBuilder.makeModel(samples: self.store.recentTokenSpeedSamples)
    }

    private var secondaryText: Color {
        TokenFloatingCardTheme.secondaryText
    }

    private var tertiaryText: Color {
        TokenFloatingCardTheme.tertiaryText
    }

    private var dividerTint: Color {
        TokenFloatingCardTheme.stroke.opacity(0.64)
    }

    private var lineTint: Color {
        TokenMenuTheme.analyticsTint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpeedPanelLayout.rootSpacing) {
            self.chartCard
                .fixedSize(horizontal: false, vertical: true)

            self.historyCard
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, TokenSpeedPanelLayout.panelHorizontalPadding)
        .padding(.vertical, TokenSpeedPanelLayout.panelVerticalPadding)
        .frame(
            width: Self.preferredPanelWidth,
            height: self.panelHeight,
            alignment: .top)
        .background(
            TokenGlassPanelBackground(
                cornerRadius: TokenSpeedPanelLayout.cornerRadius,
                tint: TokenMenuTheme.panelGlassTint))
        .clipShape(self.panelShape)
        .environment(\.locale, self.strings.locale)
    }

    private var chartCard: some View {
        self.card(accent: TokenMenuTheme.analyticsTint) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    self.moduleHeader(self.strings.tokenSpeedCurveTitle, systemImage: "waveform.path.ecg")

                    Spacer(minLength: 0)

                    self.floatingChartButton
                }
                .contentShape(Rectangle())
                .onHover { isHovered in
                    withAnimation(.easeOut(duration: 0.16)) {
                        self.showsFloatingChartButton = isHovered
                    }
                }

                TokenSpeedThroughputChartView(
                    model: self.chartModel,
                    strings: self.strings,
                    lineTint: self.lineTint,
                    plotHeight: TokenSpeedPanelLayout.plotHeight,
                    axisRowHeight: TokenSpeedPanelLayout.axisRowHeight)
            }
        }
    }

    private var historyCard: some View {
        self.card(accent: TokenMenuTheme.analyticsTint.opacity(0.72)) {
            VStack(alignment: .leading, spacing: 0) {
                self.moduleHeader(self.strings.tokenSpeedHistoryTitle, systemImage: "list.bullet.rectangle")

                if self.store.tokenSpeedHistoryEntries.isEmpty {
                    Text(self.strings.noTokenSpeedHistoryData)
                        .font(.system(size: 12))
                        .foregroundStyle(self.tertiaryText)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: TokenSpeedPanelLayout.emptyStateMinHeight,
                            alignment: .center)
                        .padding(.top, TokenSpeedPanelLayout.historyListTopSpacing)
                } else {
                    self.historyList
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func historyRow(_ entry: TokenSpeedHistoryEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(self.historyTimestampText(for: entry.timestamp))
                .font(.system(size: TokenSpeedPanelLayout.timeFontSize, weight: .medium))
                .foregroundStyle(self.secondaryText)
                .monospacedDigit()
                .frame(width: 62, alignment: .leading)

            Text(self.strings.tokenSpeedHistoryValueText(entry.tokens))
                .font(.system(size: TokenSpeedPanelLayout.valueFontSize, weight: .semibold))
                .foregroundStyle(TokenMenuTheme.analyticsTint)
                .monospacedDigit()
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(entry.icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.bottom, 1)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(self.dividerTint.opacity(0.18))
                .frame(height: 1)
                .offset(y: 6)
        }
    }

    private func moduleHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(self.secondaryText)
            .labelStyle(.titleAndIcon)
            .imageScale(.small)
            .lineLimit(1)
    }

    private func card(accent: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(TokenSpeedPanelLayout.chartCardPadding)
            .background {
                TokenFloatingCardBackground(
                    cornerRadius: TokenSpeedPanelLayout.cardCornerRadius,
                    tint: accent)
            }
    }

    private func historyTimestampText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = self.strings.locale
        formatter.calendar = Calendar.current
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private var floatingChartButton: some View {
        Button {
            self.onToggleFloatingChart()
        } label: {
            Image(systemName: self.isFloatingChartPresented
                ? "rectangle.compress.vertical"
                : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: TokenSpeedPanelLayout.headerActionIconSize, weight: .semibold))
                .foregroundStyle(self.secondaryText)
                .frame(
                    width: TokenSpeedPanelLayout.headerActionButtonSize,
                    height: TokenSpeedPanelLayout.headerActionButtonSize)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            self.isFloatingChartPresented
                                ? TokenMenuTheme.analyticsTint.opacity(0.18)
                                : TokenFloatingCardTheme.cardTop.opacity(0.48))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            self.isFloatingChartPresented
                                ? TokenMenuTheme.analyticsTint.opacity(0.62)
                                : TokenFloatingCardTheme.stroke.opacity(0.46),
                            lineWidth: 0.7)
                }
        }
        .buttonStyle(.plain)
        .opacity((self.showsFloatingChartButton || self.isFloatingChartPresented) ? 1 : 0)
        .allowsHitTesting(self.showsFloatingChartButton || self.isFloatingChartPresented)
        .help(self.strings.tokenSpeedFloatingChartButtonText(isPresented: self.isFloatingChartPresented))
        .accessibilityLabel(self.strings.tokenSpeedFloatingChartButtonText(isPresented: self.isFloatingChartPresented))
    }
}
