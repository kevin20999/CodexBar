import CodexBarCore
import SwiftUI

enum UsageOverviewLayoutMetrics {
    static let detailedRowHeight: CGFloat = 64
    static let numericGridSpacing: CGFloat = 10
    static let numericCardMinHeight: CGFloat = 100
    static var numericPlaceholderHeight: CGFloat {
        (self.numericCardMinHeight * 2) + self.numericGridSpacing
    }

    static let compactSummaryLineHeight: CGFloat = 11
}

struct UsageOverviewCardView: View {
    struct Row: Identifiable {
        let id: String
        let title: String
        let stats: DailyTokenStats
        var secondaryStats: DailyTokenStats?
        let inputFraction: Double
        let outputFraction: Double
        var segments: [UsageOverviewSegment] = []
    }

    let rows: [Row]
    let strings: AppStrings
    let usesFloatingStyle: Bool
    let compactMode: Bool

    private var labelColumnWidth: CGFloat {
        self.compactMode ? 60 : 74
    }

    private var columnSpacing: CGFloat {
        self.compactMode ? 10 : 14
    }

    private var rowHorizontalPadding: CGFloat {
        self.compactMode ? 8 : 10
    }

    private var rowVerticalPadding: CGFloat {
        self.compactMode ? 6 : 5
    }

    private var rowSpacing: CGFloat {
        self.compactMode ? 6 : 5
    }

    private var moduleOuterInset: CGFloat {
        self.compactMode ? 1 : 1
    }

    private var rowTitleFontSize: CGFloat {
        self.compactMode ? 13.5 : 14.5
    }

    private var primaryText: Color {
        self.usesFloatingStyle ? TokenFloatingCardTheme.primaryText : TokenMenuTheme.primaryText
    }

    private var dividerTint: Color {
        self.usesFloatingStyle
            ? TokenFloatingCardTheme.stroke.opacity(0.62)
            : TokenMenuTheme.quotaDivider.opacity(0.92)
    }

    private var secondaryText: Color {
        self.usesFloatingStyle ? TokenFloatingCardTheme.secondaryText : TokenMenuTheme.secondaryText.opacity(0.78)
    }

    static func leadingSubtitle(for _: Row, strings _: AppStrings) -> String? {
        nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(self.rows.enumerated()), id: \.element.id) { index, row in
                self.rowView(row)

                if index < self.rows.count - 1 {
                    self.rowDivider
                        .padding(.horizontal, self.rowHorizontalPadding)
                        .padding(.vertical, self.rowSpacing)
                }
            }
        }
        .padding(.horizontal, self.moduleOuterInset)
        .padding(.bottom, self.moduleOuterInset)
    }

    private func metricColumns(
        alignment: VerticalAlignment,
        @ViewBuilder label: () -> some View,
        @ViewBuilder input: () -> some View,
        @ViewBuilder output: () -> some View)
        -> some View
    {
        HStack(alignment: alignment, spacing: self.columnSpacing) {
            label()
                .frame(width: self.labelColumnWidth, alignment: .leading)

            input()
                .frame(maxWidth: .infinity, alignment: .leading)

            output()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(self.dividerTint)
            .frame(height: 1)
    }

    private func rowView(_ row: Row) -> some View {
        self.metricColumns(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.system(size: self.rowTitleFontSize, weight: .semibold))
                    .foregroundStyle(self.primaryText)
                    .lineLimit(1)

                if let leadingSubtitle = Self.leadingSubtitle(for: row, strings: self.strings) {
                    Text(leadingSubtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(self.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 1)
        } input: {
            UsageOverviewMetricCell(
                value: row.stats.inputTokens,
                secondaryValue: row.secondaryStats?.inputTokens,
                fraction: row.inputFraction,
                segments: row.segments,
                role: .input,
                strings: self.strings,
                usesFloatingStyle: self.usesFloatingStyle,
                compactMode: self.compactMode)
        } output: {
            UsageOverviewMetricCell(
                value: row.stats.outputTokens,
                secondaryValue: row.secondaryStats?.outputTokens,
                fraction: row.outputFraction,
                segments: row.segments,
                role: .output,
                strings: self.strings,
                usesFloatingStyle: self.usesFloatingStyle,
                compactMode: self.compactMode)
        }
        .padding(.horizontal, self.rowHorizontalPadding)
        .padding(.vertical, self.rowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum UsageOverviewMetricRole: Equatable {
    case input
    case output
}

private struct UsageOverviewMetricCell: View {
    let value: Int
    let secondaryValue: Int?
    let fraction: Double
    let segments: [UsageOverviewSegment]
    let role: UsageOverviewMetricRole
    let strings: AppStrings
    let usesFloatingStyle: Bool
    let compactMode: Bool

    private var exactText: String {
        UsageStore.exactTokenText(self.value, locale: self.strings.locale)
    }

    private var totalCompactText: String {
        self.strings.totalTokenText(self.value)
    }

    private var secondaryText: String? {
        guard let secondaryValue else { return nil }
        return self.strings.mainThreadTokenText(secondaryValue)
    }

    private var secondaryLineText: String {
        self.secondaryText ?? " "
    }

    private var metricSpacing: CGFloat {
        self.compactMode ? 2 : 2
    }

    private var valueMinHeight: CGFloat {
        self.compactMode ? 18 : 20
    }

    private var compactLineHeight: CGFloat {
        UsageOverviewLayoutMetrics.compactSummaryLineHeight
    }

    private var valueFontSize: CGFloat {
        self.compactMode ? 13.5 : 14.5
    }

    private var compactFontSize: CGFloat {
        self.compactMode ? 10 : 10
    }

    private var compactTextBottomGap: CGFloat {
        self.compactMode ? 4 : 4
    }

    private var compactLineSpacing: CGFloat {
        self.compactMode ? 1 : 1
    }

    private var tint: Color {
        switch self.role {
        case .input:
            self.usesFloatingStyle
                ? TokenFloatingCardTheme.valueColor(for: .input)
                : TokenMenuTheme.inputTint
        case .output:
            self.usesFloatingStyle
                ? TokenFloatingCardTheme.valueColor(for: .output)
                : TokenMenuTheme.outputTint
        }
    }

    private var accentRole: TokenMetricAccentRole {
        switch self.role {
        case .input:
            .input
        case .output:
            .output
        }
    }

    private var valueStyle: AnyShapeStyle {
        AnyShapeStyle(TokenFloatingCardTheme.valueGradient(for: self.accentRole))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: self.compactTextBottomGap) {
            VStack(alignment: .leading, spacing: self.metricSpacing) {
                Text(self.exactText)
                    .font(.system(size: self.valueFontSize, weight: .bold))
                    .foregroundStyle(self.valueStyle)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(minHeight: self.valueMinHeight, alignment: .topLeading)

                VStack(alignment: .leading, spacing: self.compactLineSpacing) {
                    Text(self.totalCompactText)
                        .font(.system(size: self.compactFontSize, weight: .regular))
                        .foregroundStyle(
                            self.usesFloatingStyle
                                ? TokenFloatingCardTheme.secondaryText.opacity(0.82)
                                : TokenMenuTheme.secondaryText.opacity(0.76))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(height: self.compactLineHeight, alignment: .topLeading)

                    Text(self.secondaryLineText)
                        .font(.system(size: self.compactFontSize, weight: .regular))
                        .foregroundStyle(
                            self.usesFloatingStyle
                                ? TokenFloatingCardTheme.secondaryText.opacity(0.82)
                                : TokenMenuTheme.secondaryText.opacity(0.76))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(height: self.compactLineHeight, alignment: .topLeading)
                        .opacity(self.secondaryText == nil ? 0 : 1)
                }
            }
            if self.segments.isEmpty {
                UsageOverviewBar(
                    fraction: self.fraction,
                    role: self.role,
                    tint: self.tint,
                    usesFloatingStyle: self.usesFloatingStyle,
                    compactMode: self.compactMode)
            } else {
                UsageOverviewSegmentedBar(
                    segments: self.segments,
                    role: self.role,
                    usesFloatingStyle: self.usesFloatingStyle,
                    compactMode: self.compactMode)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: UsageOverviewLayoutMetrics.detailedRowHeight,
            alignment: .topLeading)
    }
}

private struct UsageOverviewBar: View {
    let fraction: Double
    let role: UsageOverviewMetricRole
    let tint: Color
    let usesFloatingStyle: Bool
    let compactMode: Bool

    private var clampedFraction: Double {
        min(max(self.fraction, 0), 1)
    }

    private var barHeight: CGFloat {
        self.compactMode ? 5 : 5
    }

    private var accentRole: TokenMetricAccentRole {
        switch self.role {
        case .input:
            .input
        case .output:
            .output
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fillWidth = width * self.clampedFraction

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(
                        self.usesFloatingStyle
                            ? TokenFloatingCardTheme.track
                            : TokenMenuTheme.progressTrack)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                self.usesFloatingStyle
                                    ? TokenFloatingCardTheme.trackStroke
                                    : TokenMenuTheme.progressTrackStroke,
                                lineWidth: 0.6))
                    .overlay(alignment: .top) {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(self.usesFloatingStyle ? 0.14 : 0.08),
                                        Color.clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom))
                            .frame(height: 2.5)
                            .clipShape(Capsule(style: .continuous))
                    }

                if fillWidth > 0 {
                    Capsule(style: .continuous)
                        .fill(self.fillStyle)
                        .frame(width: min(fillWidth, width))
                        .overlay(alignment: .top) {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(self.usesFloatingStyle ? 0.24 : 0.14),
                                            Color.clear,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom))
                                .frame(height: 2.5)
                                .clipShape(Capsule(style: .continuous))
                        }
                        .shadow(
                            color: self.shadowColor.opacity(self.usesFloatingStyle ? 0.26 : 0.18),
                            radius: 4,
                            x: 0,
                            y: 0)
                }
            }
        }
        .frame(height: self.barHeight)
        .animation(.easeInOut(duration: 0.28), value: self.clampedFraction)
    }

    private var fillStyle: LinearGradient {
        TokenFloatingCardTheme.progressGradient(for: self.accentRole)
    }

    private var shadowColor: Color {
        TokenFloatingCardTheme.glowColor(for: self.accentRole)
    }
}

private struct UsageOverviewSegmentedBar: View {
    let segments: [UsageOverviewSegment]
    let role: UsageOverviewMetricRole
    let usesFloatingStyle: Bool
    let compactMode: Bool

    private var clampedSegments: [UsageOverviewSegment] {
        self.segments.filter { segment in
            switch self.role {
            case .input:
                segment.inputFraction > 0
            case .output:
                segment.outputFraction > 0
            }
        }
    }

    private var barHeight: CGFloat {
        self.compactMode ? 5 : 5
    }

    private var segmentSpacing: CGFloat {
        self.compactMode ? 0.5 : 0.5
    }

    private var accentRole: TokenMetricAccentRole {
        switch self.role {
        case .input:
            .input
        case .output:
            .output
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let layouts = self.segmentLayouts(totalWidth: proxy.size.width)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(
                        self.usesFloatingStyle
                            ? TokenFloatingCardTheme.track
                            : TokenMenuTheme.progressTrack)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                self.usesFloatingStyle
                                    ? TokenFloatingCardTheme.trackStroke
                                    : TokenMenuTheme.progressTrackStroke,
                                lineWidth: 0.6))

                HStack(spacing: self.segmentSpacing) {
                    ForEach(layouts, id: \.segment.id) { layout in
                        RoundedRectangle(cornerRadius: self.barHeight / 2, style: .continuous)
                            .fill(TokenFloatingCardTheme.progressGradient(for: self.accentRole))
                            .frame(width: layout.frame.width)
                            .overlay(alignment: .top) {
                                RoundedRectangle(cornerRadius: self.barHeight / 2, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(self.usesFloatingStyle ? 0.24 : 0.14),
                                                Color.clear,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom))
                                    .frame(height: 2.5)
                                    .clipShape(RoundedRectangle(cornerRadius: self.barHeight / 2, style: .continuous))
                            }
                            .shadow(
                                color: TokenFloatingCardTheme.glowColor(for: self.accentRole)
                                    .opacity(self.usesFloatingStyle ? 0.26 : 0.18),
                                radius: 4,
                                x: 0,
                                y: 0)
                    }
                }
            }
        }
        .frame(height: self.barHeight)
    }

    private struct SegmentLayout {
        let segment: UsageOverviewSegment
        let frame: CGRect
    }

    private func segmentLayouts(totalWidth: CGFloat) -> [SegmentLayout] {
        let segments = self.clampedSegments
        guard !segments.isEmpty else { return [] }

        let totalSpacing = self.segmentSpacing * CGFloat(max(segments.count - 1, 0))
        let drawableWidth = max(totalWidth - totalSpacing, 0)
        var currentX: CGFloat = 0

        return segments.map { segment in
            let width = drawableWidth * self.fraction(for: segment)
            let frame = CGRect(x: currentX, y: 0, width: width, height: self.barHeight)
            currentX += width + self.segmentSpacing
            return SegmentLayout(segment: segment, frame: frame)
        }
    }

    private func fraction(for segment: UsageOverviewSegment) -> CGFloat {
        switch self.role {
        case .input:
            CGFloat(segment.inputFraction)
        case .output:
            CGFloat(segment.outputFraction)
        }
    }
}
