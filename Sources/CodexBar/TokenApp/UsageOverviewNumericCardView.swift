import SwiftUI

struct UsageOverviewNumericCardView: View {
    struct Item: Identifiable {
        let id: String
        let title: String
        let primaryAmountText: String
        let primaryUnitText: String?
        let secondaryLabelText: String?
        let secondaryAmountText: String?
        let secondaryUnitText: String?
        let accessibilityText: String
    }

    let items: [Item]

    private let columns = [
        GridItem(.flexible(minimum: 0), spacing: UsageOverviewLayoutMetrics.numericGridSpacing),
        GridItem(.flexible(minimum: 0), spacing: UsageOverviewLayoutMetrics.numericGridSpacing),
    ]

    private let primaryGradient = TokenFloatingCardTheme.valueGradient(for: .input)

    private var titleFont: Font {
        .system(size: 13, weight: .semibold)
    }

    private var primaryAmountFont: Font {
        .system(size: 28, weight: .bold)
    }

    private var primaryUnitFont: Font {
        .system(size: 14, weight: .semibold)
    }

    private var secondaryLabelFont: Font {
        .system(size: 10, weight: .medium)
    }

    private var secondaryAmountFont: Font {
        .system(size: 18, weight: .semibold)
    }

    private var secondaryUnitFont: Font {
        .system(size: 12, weight: .medium)
    }

    var body: some View {
        LazyVGrid(columns: self.columns, alignment: .leading, spacing: UsageOverviewLayoutMetrics.numericGridSpacing) {
            ForEach(self.items) { item in
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.title)
                        .font(self.titleFont)
                        .foregroundStyle(TokenFloatingCardTheme.secondaryText)
                        .lineLimit(1)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(item.primaryAmountText)
                                .font(self.primaryAmountFont)
                                .foregroundStyle(self.primaryGradient)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            if let primaryUnitText = item.primaryUnitText {
                                Text(primaryUnitText)
                                    .font(self.primaryUnitFont)
                                    .foregroundStyle(self.primaryGradient)
                                    .lineLimit(1)
                                    .opacity(0.84)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.secondaryLabelText ?? " ")
                                .font(self.secondaryLabelFont)
                                .foregroundStyle(TokenFloatingCardTheme.secondaryText)
                                .lineLimit(1)
                                .opacity(item.secondaryAmountText == nil ? 0 : 0.72)

                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(item.secondaryAmountText ?? " ")
                                    .font(self.secondaryAmountFont)
                                    .foregroundStyle(TokenFloatingCardTheme.secondaryText.opacity(0.92))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)

                                if let secondaryUnitText = item.secondaryUnitText {
                                    Text(secondaryUnitText)
                                        .font(self.secondaryUnitFont)
                                        .foregroundStyle(TokenFloatingCardTheme.secondaryText.opacity(0.78))
                                        .lineLimit(1)
                                }
                            }
                            .opacity(item.secondaryAmountText == nil ? 0 : 1)
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: UsageOverviewLayoutMetrics.numericCardMinHeight,
                    alignment: .topLeading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    TokenFloatingInsetBackground(
                        cornerRadius: 16,
                        tint: TokenMenuTheme.analyticsTint))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.accessibilityText)
            }
        }
    }
}
