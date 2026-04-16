import SwiftUI

struct TokenHoverTooltipMetricContent: Equatable, Identifiable {
    let id: String
    let title: String
    let exactText: String
    let compactText: String?
    let role: TokenMetricAccentRole
}

enum TokenHoverTooltipStyle {
    static let width: CGFloat = 150
    static let height: CGFloat = 116
    static let gap: CGFloat = 12

    static var transition: AnyTransition {
        .opacity
            .combined(with: .scale(scale: 0.96, anchor: .bottom))
            .combined(with: .offset(y: 6))
    }

    static var animation: Animation {
        .spring(response: 0.24, dampingFraction: 0.84)
    }
}

struct TokenHoverTooltip: View {
    let title: String
    let metrics: [TokenHoverTooltipMetricContent]
    let tint: Color
    let usesFloatingStyle: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    TokenMenuTheme.tooltipPrimaryText(
                        for: self.colorScheme,
                        usesFloatingStyle: self.usesFloatingStyle))

            VStack(alignment: .leading, spacing: 5) {
                ForEach(self.metrics) { metric in
                    TokenHoverTooltipMetric(
                        metric: metric,
                        usesFloatingStyle: self.usesFloatingStyle)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            TokenChartTooltipBackground(cornerRadius: 12, tint: self.tint)
        }
    }
}

private struct TokenHoverTooltipMetric: View {
    let metric: TokenHoverTooltipMetricContent
    let usesFloatingStyle: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 1.5) {
            HStack(spacing: 5) {
                Circle()
                    .fill(TokenFloatingCardTheme.valueColor(for: self.metric.role))
                    .frame(width: 5, height: 5)

                Text(self.metric.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        TokenMenuTheme.tooltipSecondaryText(
                            for: self.colorScheme,
                            usesFloatingStyle: self.usesFloatingStyle))
            }

            Text(self.metric.exactText)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(
                    TokenMenuTheme.tooltipValueGradient(
                        for: self.metric.role,
                        colorScheme: self.colorScheme))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(self.metric.compactText ?? " ")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(
                    TokenMenuTheme.tooltipTertiaryText(
                        for: self.colorScheme,
                        usesFloatingStyle: self.usesFloatingStyle))
                .lineLimit(1)
                .opacity(self.metric.compactText == nil ? 0 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
