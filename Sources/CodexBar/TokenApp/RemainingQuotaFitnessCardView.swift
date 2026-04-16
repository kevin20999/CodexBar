import SwiftUI

enum RemainingQuotaFitnessHeaderVisibility {
    static func metadataText(
        accountHeaderText: String?,
        accountPlan: String?,
        updatedDescription: String?,
        metadataLinkURL: URL? = nil)
        -> AttributedString?
    {
        let parts = [
            MetadataPart(text: self.trimmedValue(accountHeaderText), usesLink: metadataLinkURL != nil),
            MetadataPart(text: self.trimmedValue(accountPlan), usesLink: metadataLinkURL != nil),
            MetadataPart(text: self.trimmedValue(updatedDescription), usesLink: false),
        ].compactMap(\.resolved)

        guard !parts.isEmpty else { return nil }

        var text = AttributedString()
        for (index, part) in parts.enumerated() {
            if index > 0 {
                text += AttributedString("  •  ")
            }

            var segment = AttributedString(part.text)
            if part.usesLink, let metadataLinkURL {
                segment.link = metadataLinkURL
            }
            text += segment
        }

        return text
    }

    static func shouldShowHeader(
        showsTitle: Bool,
        showsCachedBadge: Bool,
        isRefreshing: Bool,
        metadataText: AttributedString?)
        -> Bool
    {
        showsTitle || showsCachedBadge || isRefreshing || self.hasMetadata(metadataText)
    }

    private static func hasMetadata(_ metadataText: AttributedString?) -> Bool {
        guard let metadataText else { return false }
        return !String(metadataText.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func trimmedValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private struct MetadataPart {
        let text: String?
        let usesLink: Bool

        var resolved: ResolvedMetadataPart? {
            guard let text else { return nil }
            return ResolvedMetadataPart(text: text, usesLink: self.usesLink)
        }
    }

    private struct ResolvedMetadataPart {
        let text: String
        let usesLink: Bool
    }
}

enum RemainingQuotaFitnessCardVariant: Equatable, Sendable {
    case general
    case spark
}

enum RemainingQuotaFitnessStatusVisibility {
    static func statusMessage(
        errorMessage: String?,
        hasQuotaData: Bool,
        emptyMessage: String)
        -> String?
    {
        if let errorMessage = self.trimmed(errorMessage) {
            return errorMessage
        }
        guard !hasQuotaData else { return nil }
        return self.trimmed(emptyMessage)
    }

    static func shouldShowFooter(for statusMessage: String?) -> Bool {
        self.trimmed(statusMessage) != nil
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum RemainingQuotaFitnessHeaderLayoutMetrics {
    static func spinnerSlotSize(compactMode: Bool) -> CGFloat {
        compactMode ? 14 : 16
    }

    static func minHeight(compactMode: Bool) -> CGFloat {
        compactMode ? 18 : 20
    }
}

private struct RemainingQuotaFitnessTheme {
    let cardGlow: Color
    let percentGradient: LinearGradient
    let progressGradient: LinearGradient
    let textPrimary = TokenFloatingCardTheme.primaryText
    let textSecondary = TokenFloatingCardTheme.secondaryText
    let textMetadata = TokenFloatingCardTheme.tertiaryText
    let divider = TokenFloatingCardTheme.stroke.opacity(0.6)
    let track = TokenFloatingCardTheme.track
    let trackStroke = TokenFloatingCardTheme.trackStroke
    let badgeFill = TokenFloatingCardTheme.track.opacity(0.64)

    static func make(for variant: RemainingQuotaFitnessCardVariant) -> RemainingQuotaFitnessTheme {
        switch variant {
        case .general:
            let accentStart = Color(red: 0.98, green: 0.39, blue: 0.18)
            let accentMid = Color(red: 1.0, green: 0.56, blue: 0.24)
            let accentEnd = Color(red: 1.0, green: 0.74, blue: 0.42)
            let gradient = LinearGradient(
                colors: [accentStart, accentMid, accentEnd],
                startPoint: .leading,
                endPoint: .trailing)
            return RemainingQuotaFitnessTheme(
                cardGlow: Color(red: 1.0, green: 0.49, blue: 0.22),
                percentGradient: gradient,
                progressGradient: gradient)
        case .spark:
            let accentStart = Color(red: 75 / 255, green: 127 / 255, blue: 234 / 255)
            let accentMid = Color(red: 73 / 255, green: 163 / 255, blue: 176 / 255)
            let accentEnd = Color(red: 184 / 255, green: 228 / 255, blue: 247 / 255)
            return RemainingQuotaFitnessTheme(
                cardGlow: Color(red: 102 / 255, green: 181 / 255, blue: 205 / 255),
                percentGradient: LinearGradient(
                    colors: [accentStart, accentMid, accentEnd],
                    startPoint: .leading,
                    endPoint: .trailing),
                progressGradient: LinearGradient(
                    colors: [accentStart.opacity(0.98), accentMid, accentEnd.opacity(0.96)],
                    startPoint: .leading,
                    endPoint: .trailing))
        }
    }
}

struct RemainingQuotaFitnessCardView: View {
    let title: String
    let themeVariant: RemainingQuotaFitnessCardVariant
    let showsTitle: Bool
    let cachedBadgeTitle: String
    let showsCachedBadge: Bool
    let cachedActionTitle: String?
    let onCachedAction: (() -> Void)?
    let isRefreshing: Bool
    let accountHeaderText: String?
    let accountPlan: String?
    let updatedDescription: String?
    let metadataLinkURL: URL?
    let quotaItems: [QuotaProgressPresentation]
    let hasQuotaData: Bool
    let emptyMessage: String
    let errorMessage: String?
    let strings: AppStrings
    let compactMode: Bool

    private var cardCornerRadius: CGFloat {
        self.compactMode ? 22 : 24
    }

    private var outerSpacing: CGFloat {
        self.compactMode ? 10 : 12
    }

    private var rowGroupSpacing: CGFloat {
        0
    }

    private var outerPadding: CGFloat {
        self.compactMode ? 10 : 12
    }

    private var headerFontSize: CGFloat {
        self.compactMode ? 11.5 : 12
    }

    private var badgeFontSize: CGFloat {
        self.compactMode ? 10.5 : 11
    }

    private var metadataFontSize: CGFloat {
        self.compactMode ? 10.5 : 11
    }

    private var dividerVerticalPadding: CGFloat {
        self.compactMode ? 5 : 7
    }

    private var headerSpinnerSlotSize: CGFloat {
        RemainingQuotaFitnessHeaderLayoutMetrics.spinnerSlotSize(compactMode: self.compactMode)
    }

    private var headerMinHeight: CGFloat {
        RemainingQuotaFitnessHeaderLayoutMetrics.minHeight(compactMode: self.compactMode)
    }

    private var metadataText: AttributedString? {
        RemainingQuotaFitnessHeaderVisibility.metadataText(
            accountHeaderText: self.accountHeaderText,
            accountPlan: self.accountPlan,
            updatedDescription: self.updatedDescription,
            metadataLinkURL: self.metadataLinkURL)
    }

    private var theme: RemainingQuotaFitnessTheme {
        RemainingQuotaFitnessTheme.make(for: self.themeVariant)
    }

    private var hasLeadingHeaderContent: Bool {
        self.showsTitle || self.showsCachedBadge || self.showsCachedAction || self.isRefreshing
    }

    private var reservesRefreshSlot: Bool {
        self.showsTitle || self.showsCachedBadge || self.showsCachedAction || self.isRefreshing
    }

    private var showsCachedAction: Bool {
        self.showsCachedBadge && self.cachedActionTitle != nil && self.onCachedAction != nil
    }

    private var shouldShowHeader: Bool {
        RemainingQuotaFitnessHeaderVisibility.shouldShowHeader(
            showsTitle: self.showsTitle,
            showsCachedBadge: self.showsCachedBadge,
            isRefreshing: self.isRefreshing,
            metadataText: self.metadataText)
    }

    private var rowItemsForDisplay: [QuotaProgressPresentation] {
        let placeholderItems = [
            QuotaProgressPresentation(
                title: self.strings.durationLabel(for: 5 * 60, fallbackPrimary: true),
                remainingPercent: 0,
                progressFraction: 0,
                resetText: "--",
                accent: .primary,
                isStale: false),
            QuotaProgressPresentation(
                title: self.strings.durationLabel(for: 7 * 24 * 60, fallbackPrimary: false),
                remainingPercent: 0,
                progressFraction: 0,
                resetText: "--",
                accent: .secondary,
                isStale: false),
        ]

        return Array((self.quotaItems + placeholderItems).prefix(2))
    }

    private var statusMessage: String? {
        RemainingQuotaFitnessStatusVisibility.statusMessage(
            errorMessage: self.errorMessage,
            hasQuotaData: self.hasQuotaData,
            emptyMessage: self.emptyMessage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: self.outerSpacing) {
            if self.shouldShowHeader {
                self.header
            }

            VStack(alignment: .leading, spacing: self.rowGroupSpacing) {
                ForEach(Array(self.rowItemsForDisplay.enumerated()), id: \.offset) { index, item in
                    if self.hasQuotaData, index < self.quotaItems.count {
                        RemainingQuotaFitnessRowView(
                            presentation: item,
                            theme: self.theme,
                            compactMode: self.compactMode)
                    } else {
                        RemainingQuotaFitnessPlaceholderRowView(
                            presentation: item,
                            theme: self.theme,
                            compactMode: self.compactMode)
                    }

                    if index < self.rowItemsForDisplay.count - 1 {
                        Rectangle()
                            .fill(self.theme.divider)
                            .frame(height: 1)
                            .padding(.vertical, self.dividerVerticalPadding)
                    }
                }
            }

            if RemainingQuotaFitnessStatusVisibility.shouldShowFooter(for: self.statusMessage),
               let statusMessage = self.statusMessage
            {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(self.hasQuotaData ? TokenMenuTheme.warningText : self.theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: self.compactMode ? 30 : 34, alignment: .topLeading)
            }
        }
        .padding(self.outerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RemainingQuotaFitnessCardBackground(cornerRadius: self.cardCornerRadius, theme: self.theme))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            if self.showsTitle {
                Label(self.title, systemImage: "gauge.with.dots.needle.50percent")
                    .font(.system(size: self.headerFontSize, weight: .semibold))
                    .foregroundStyle(self.theme.textSecondary)
                    .labelStyle(.titleAndIcon)
                    .imageScale(.small)
                    .lineLimit(1)
            }

            if self.showsCachedBadge {
                Text(self.cachedBadgeTitle)
                    .font(.system(size: self.badgeFontSize, weight: .semibold))
                    .foregroundStyle(self.theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, self.compactMode ? 3.5 : 4)
                    .background(Capsule().fill(self.theme.badgeFill))
            }

            if self.showsCachedAction, let cachedActionTitle, let onCachedAction {
                Button(action: onCachedAction) {
                    Text(cachedActionTitle)
                }
                .buttonStyle(QuotaHeaderActionButtonStyle(theme: self.theme, compactMode: self.compactMode))
            }

            if self.reservesRefreshSlot {
                ProgressView()
                    .controlSize(.small)
                    .tint(self.theme.cardGlow)
                    .opacity(self.isRefreshing ? 1 : 0)
                    .frame(width: self.headerSpinnerSlotSize, height: self.headerSpinnerSlotSize)
                    .accessibilityHidden(true)
            }

            if let metadataText {
                Spacer(minLength: self.hasLeadingHeaderContent ? 8 : 0)

                Text(metadataText)
                    .font(.system(size: self.metadataFontSize, weight: .medium))
                    .foregroundStyle(self.theme.textMetadata)
                    .tint(self.theme.textMetadata)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 220, alignment: .trailing)
            }
        }
        .frame(minHeight: self.headerMinHeight, alignment: .leading)
    }
}

private struct QuotaHeaderActionButtonStyle: ButtonStyle {
    let theme: RemainingQuotaFitnessTheme
    let compactMode: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: self.compactMode ? 10.5 : 11, weight: .semibold))
            .foregroundStyle(configuration.isPressed ? self.theme.textPrimary.opacity(0.84) : self.theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, self.compactMode ? 3.5 : 4)
            .background(
                Capsule()
                    .fill(self.theme.badgeFill.opacity(configuration.isPressed ? 0.78 : 0.92)))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct RemainingQuotaFitnessRowView: View {
    let presentation: QuotaProgressPresentation
    let theme: RemainingQuotaFitnessTheme

    let compactMode: Bool

    private var rowSpacing: CGFloat {
        self.compactMode ? 4 : 6
    }

    private var titleFontSize: CGFloat {
        self.compactMode ? 16 : 17
    }

    private var percentFontSize: CGFloat {
        self.compactMode ? 23 : 27
    }

    private var subtitleFontSize: CGFloat {
        self.compactMode ? 10.5 : 11
    }

    private var textStackSpacing: CGFloat {
        self.compactMode ? 8 : 10
    }

    private var resetInfoSpacing: CGFloat {
        self.compactMode ? 3 : 4
    }

    private var metricBlockHeight: CGFloat {
        self.compactMode ? 32 : 36
    }

    private var percentColumnWidth: CGFloat {
        self.compactMode ? 70 : 82
    }

    private var horizontalPadding: CGFloat {
        0
    }

    private var verticalPadding: CGFloat {
        self.compactMode ? 2 : 3
    }

    private var resetText: String {
        self.presentation.resetText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showsResetIcon: Bool {
        let text = self.resetText
        return !text.isEmpty && text != "--"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: self.rowSpacing) {
            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .center, spacing: self.textStackSpacing) {
                    Text(self.presentation.title)
                        .font(.system(size: self.titleFontSize, weight: .medium))
                        .foregroundStyle(self.theme.textPrimary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    HStack(alignment: .center, spacing: self.resetInfoSpacing) {
                        if self.showsResetIcon {
                            Image(systemName: "hourglass")
                                .font(.system(size: self.subtitleFontSize - 0.5, weight: .medium))
                                .foregroundStyle(self.theme.textSecondary)
                                .imageScale(.small)
                        }

                        Text(self.resetText)
                            .font(.system(size: self.subtitleFontSize, weight: .regular))
                            .foregroundStyle(self.theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: self.metricBlockHeight, alignment: .leading)

                Text("\(Int(self.presentation.remainingPercent.rounded()))%")
                    .font(.system(size: self.percentFontSize, weight: .bold))
                    .foregroundStyle(self.theme.percentGradient)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(
                        width: self.percentColumnWidth,
                        height: self.metricBlockHeight,
                        alignment: .trailing)
            }

            RemainingQuotaFitnessProgressBar(
                fraction: self.presentation.progressFraction,
                theme: self.theme,
                compactMode: self.compactMode)
        }
        .padding(.horizontal, self.horizontalPadding)
        .padding(.vertical, self.verticalPadding)
    }
}

private struct RemainingQuotaFitnessProgressBar: View {
    let fraction: Double
    let theme: RemainingQuotaFitnessTheme
    let compactMode: Bool

    private var clampedFraction: Double {
        min(max(self.fraction, 0), 1)
    }

    private var barHeight: CGFloat {
        self.compactMode ? 8 : 10
    }

    private var minimumFillWidth: CGFloat {
        self.compactMode ? 10 : 12
    }

    private var highlightHeight: CGFloat {
        self.compactMode ? 3 : 4
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fillWidth = self.clampedFraction == 0
                ? 0
                : max(width * self.clampedFraction, self.minimumFillWidth)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(self.theme.track)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(self.theme.trackStroke, lineWidth: 0.8))

                if fillWidth > 0 {
                    Capsule(style: .continuous)
                        .fill(self.theme.progressGradient)
                        .frame(width: min(fillWidth, width))
                        .overlay(alignment: .top) {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.34), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom))
                                .frame(height: self.highlightHeight)
                                .clipShape(Capsule(style: .continuous))
                        }
                        .shadow(color: self.theme.cardGlow.opacity(0.28), radius: 12, x: 0, y: 0)
                }
            }
        }
        .frame(height: self.barHeight)
        .animation(.easeInOut(duration: 0.35), value: self.clampedFraction)
    }
}

private struct RemainingQuotaFitnessPlaceholderRowView: View {
    let presentation: QuotaProgressPresentation
    let theme: RemainingQuotaFitnessTheme
    let compactMode: Bool

    private var rowSpacing: CGFloat {
        self.compactMode ? 4 : 6
    }

    private var titleFontSize: CGFloat {
        self.compactMode ? 16 : 17
    }

    private var percentFontSize: CGFloat {
        self.compactMode ? 23 : 27
    }

    private var subtitleFontSize: CGFloat {
        self.compactMode ? 10.5 : 11
    }

    private var textStackSpacing: CGFloat {
        self.compactMode ? 8 : 10
    }

    private var metricBlockHeight: CGFloat {
        self.compactMode ? 32 : 36
    }

    private var percentColumnWidth: CGFloat {
        self.compactMode ? 70 : 82
    }

    private var verticalPadding: CGFloat {
        self.compactMode ? 2 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: self.rowSpacing) {
            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .center, spacing: self.textStackSpacing) {
                    Text(self.presentation.title)
                        .font(.system(size: self.titleFontSize, weight: .medium))
                        .foregroundStyle(self.theme.textPrimary.opacity(0.74))
                        .lineLimit(1)
                        .layoutPriority(1)

                    Text("--")
                        .font(.system(size: self.subtitleFontSize, weight: .regular))
                        .foregroundStyle(self.theme.textSecondary.opacity(0.82))
                        .lineLimit(1)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: self.metricBlockHeight, alignment: .leading)

                Text("--")
                    .font(.system(size: self.percentFontSize, weight: .bold))
                    .foregroundStyle(self.theme.textSecondary.opacity(0.82))
                    .monospacedDigit()
                    .lineLimit(1)
                    .frame(
                        width: self.percentColumnWidth,
                        height: self.metricBlockHeight,
                        alignment: .trailing)
            }

            RemainingQuotaFitnessProgressBar(
                fraction: 0,
                theme: self.theme,
                compactMode: self.compactMode)
        }
        .padding(.vertical, self.verticalPadding)
    }
}

private struct RemainingQuotaFitnessCardBackground: View {
    let cornerRadius: CGFloat
    let theme: RemainingQuotaFitnessTheme

    var body: some View {
        TokenFloatingCardBackground(
            cornerRadius: self.cornerRadius,
            tint: self.theme.cardGlow)
            .overlay {
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                self.theme.cardGlow.opacity(0.36),
                                Color.clear,
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing),
                        lineWidth: 1)
            }
    }
}
