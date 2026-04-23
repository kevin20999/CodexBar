import AppKit
import Charts
import CodexBarCore
import Logging
import SwiftUI

struct ThirtyDayChartDay: Identifiable, Equatable, Sendable {
    let stats: DailyTokenStats
    let date: Date

    var id: String {
        self.stats.date
    }
}

struct ThirtyDayChartModel: Equatable, Sendable {
    let days: [ThirtyDayChartDay]
    let bars: [ThirtyDayChartBar]
    let axisDates: [Date]
    let axisMarkers: [TokenChartAxisMarker]
    let peakDayID: String?

    var peakBar: ThirtyDayChartBar? {
        guard let peakDayID else { return nil }
        return self.bars.first(where: { $0.day.id == peakDayID && $0.value > 0 })
    }
}

struct ThirtyDayChartBar: Identifiable, Equatable, Sendable {
    let day: ThirtyDayChartDay
    let value: Int

    var id: String {
        self.day.id
    }
}

struct UsageOverviewNumericItem: Identifiable {
    let id: String
    let title: String
    let value: Int
    let primaryAmountText: String
    let primaryUnitText: String?
    let secondaryLabelText: String?
    let secondaryAmountText: String?
    let secondaryUnitText: String?
    let accessibilityText: String
}

enum UsageOverviewPresentationBuilder {
    @MainActor
    static func rowCount(settings: SettingsStore) -> Int {
        [
            settings.showTodayUsageCard,
            settings.showSevenDayUsageCard,
            settings.showThirtyDayUsageCard,
            settings.showAllTimeUsageCard,
        ]
            .count(where: { $0 })
    }

    @MainActor
    static func rows(
        store: UsageStore,
        settings: SettingsStore,
        strings: AppStrings)
        -> [UsageOverviewCardView.Row]
    {
        let thirtyDayInputTotal = store.thirtyDayTotal.inputTokens
        let thirtyDayOutputTotal = store.thirtyDayTotal.outputTokens
        let thirtyDaySegments = UsageOverviewSegmentation.rollingWeekSegments(
            days: store.trailingThirtyDays,
            strings: strings)
        let cumulativeSegments = UsageOverviewSegmentation.monthlySegments(
            days: store.days,
            strings: strings)

        return [
            settings.showTodayUsageCard ? UsageOverviewCardView.Row(
                id: "today",
                title: strings.todayUsageTitle,
                stats: store.today,
                secondaryStats: store.regularToday,
                inputFraction: UsageOverviewSegmentation.normalizedFraction(
                    value: store.today.inputTokens,
                    total: thirtyDayInputTotal),
                outputFraction: UsageOverviewSegmentation.normalizedFraction(
                    value: store.today.outputTokens,
                    total: thirtyDayOutputTotal))
                : nil,
            settings.showSevenDayUsageCard
                ? UsageOverviewCardView.Row(
                    id: "seven-day",
                    title: strings.sevenDayTotalTitle(),
                    stats: store.sevenDayTotal,
                    secondaryStats: store.regularSevenDayTotal,
                    inputFraction: UsageOverviewSegmentation.normalizedFraction(
                        value: store.sevenDayTotal.inputTokens,
                        total: thirtyDayInputTotal),
                    outputFraction: UsageOverviewSegmentation.normalizedFraction(
                        value: store.sevenDayTotal.outputTokens,
                        total: thirtyDayOutputTotal))
                : nil,
            settings.showThirtyDayUsageCard
                ? UsageOverviewCardView.Row(
                    id: "thirty-day",
                    title: strings.thirtyDayTotalTitle(),
                    stats: store.thirtyDayTotal,
                    secondaryStats: store.regularThirtyDayTotal,
                    inputFraction: 1,
                    outputFraction: 1,
                    segments: thirtyDaySegments)
                : nil,
            settings.showAllTimeUsageCard
                ? UsageOverviewCardView.Row(
                    id: "all-time",
                    title: strings.allTimeTotalTitle(),
                    stats: store.cumulativeTotal,
                    secondaryStats: store.regularCumulativeTotal,
                    inputFraction: 1,
                    outputFraction: 1,
                    segments: cumulativeSegments)
                : nil,
        ].compactMap(\.self)
    }

    @MainActor
    static func numericItems(store: UsageStore, strings: AppStrings) -> [UsageOverviewNumericItem] {
        func makeItem(id: String, title: String, totalValue: Int, mainThreadValue: Int) -> UsageOverviewNumericItem {
            let totalParts = strings.compactTokenParts(totalValue)
            let mainThreadParts = strings.compactTokenParts(mainThreadValue)

            return UsageOverviewNumericItem(
                id: id,
                title: title,
                value: totalValue,
                primaryAmountText: totalParts.amountText,
                primaryUnitText: totalParts.unitText,
                secondaryLabelText: strings.mainThreadLabel,
                secondaryAmountText: mainThreadParts.amountText,
                secondaryUnitText: mainThreadParts.unitText,
                accessibilityText: strings.usageOverviewNumericAccessibilityText(
                    title: title,
                    totalValue: totalValue,
                    mainThreadValue: mainThreadValue))
        }

        return [
            makeItem(
                id: "today",
                title: strings.todayUsageTitle,
                totalValue: store.today.totalTokens,
                mainThreadValue: store.regularToday.totalTokens),
            makeItem(
                id: "seven-day",
                title: strings.sevenDayTotalTitle(),
                totalValue: store.sevenDayTotal.totalTokens,
                mainThreadValue: store.regularSevenDayTotal.totalTokens),
            makeItem(
                id: "thirty-day",
                title: strings.thirtyDayTotalTitle(),
                totalValue: store.thirtyDayTotal.totalTokens,
                mainThreadValue: store.regularThirtyDayTotal.totalTokens),
            makeItem(
                id: "all-time",
                title: strings.allTimeTotalTitle(),
                totalValue: store.cumulativeTotal.totalTokens,
                mainThreadValue: store.regularCumulativeTotal.totalTokens),
        ]
    }
}

private typealias ThirtyDayChartScale = DashboardThirtyDayChartScale
private typealias ThirtyDayChartScaleResolver = DashboardThirtyDayChartScaleResolver

enum ThirtyDayChartPeakResolver {
    static func peakDayID(from days: [DailyTokenStats]) -> String? {
        guard let peak = days.max(by: isOrderedAscending), peak.totalTokens > 0 else { return nil }
        return peak.id
    }

    private static func isOrderedAscending(_ lhs: DailyTokenStats, _ rhs: DailyTokenStats) -> Bool {
        if lhs.totalTokens == rhs.totalTokens {
            return lhs.date < rhs.date
        }
        return lhs.totalTokens < rhs.totalTokens
    }
}

private typealias ThirtyDayChartStyle = DashboardThirtyDayBarStyle

private func thirtyDayChartScale(for model: ThirtyDayChartModel) -> ThirtyDayChartScale {
    let peakValue = model.peakBar?.value ?? 0
    let topValue = ThirtyDayChartScaleResolver.topValue(forPeakValue: peakValue)
    return ThirtyDayChartScale(topValue: topValue)
}

private func niceChartCeiling(for value: Int) -> Int {
    guard value > 0 else { return 2 }

    let magnitude = pow(10.0, floor(log10(Double(value))))
    let scaled = Double(value) / magnitude
    let factor: Double = switch scaled {
    case ...1:
        1
    case ...2:
        2
    case ...4:
        4
    case ...5:
        5
    case ...8:
        8
    default:
        10
    }

    return max(2, Int((factor * magnitude).rounded()))
}

private func thirtyDayBarGlow() -> Color {
    dashboardThirtyDayBarGlow()
}

private func chartGridTint(usesFloatingLowerCards: Bool) -> Color {
    dashboardChartGridTint(usesFloatingLowerCards: usesFloatingLowerCards)
}

private func chartAxisTint(usesFloatingLowerCards: Bool) -> Color {
    dashboardChartAxisTint(usesFloatingLowerCards: usesFloatingLowerCards)
}

private func thirtyDayDisplayedBarValue(for value: Int, scale: ThirtyDayChartScale) -> Double {
    dashboardThirtyDayDisplayedBarValue(for: value, scale: scale)
}

@MainActor
struct MenuBarLabel: View {
    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore

    var body: some View {
        let labelText = self.store.menuBarText(for: self.settings.menuBarDisplayMode)

        RenderedMenuBarPreview(
            mode: self.settings.menuBarDisplayMode,
            metrics: self.store.menuBarDisplayMetrics,
            quotaStyle: self.settings.menuBarQuotaStyle,
            fallbackText: labelText,
            targetHeight: MenuBarDisplayRenderer.menuBarTargetHeight)
            .id(
                "\(self.settings.menuBarDisplayMode.rawValue)-\(self.settings.menuBarQuotaStyle.rawValue)-\(labelText)")
    }
}

@MainActor
struct MenuContent: View {
    private static let renderLogger = Logger(label: "CodexBar.token-menu-panel.render")

    enum TokenMenuPanelRenderPhaseMode: Equatable {
        case coldStart(signatureIdentity: String)
        case warmed
    }

    enum TokenMenuContentRenderPhase: Int, Comparable {
        case quotaHeroes
        case usageOverviewNumeric
        case messageActivityShell
        case messageActivityChart
        case summaryShell
        case summary
        case thirtyDayChartShell
        case thirtyDayChart
        case recentTwentyFourHourChartShell
        case recentTwentyFourHourChart
        case webCardsShell
        case webCards
        case full

        static func < (lhs: TokenMenuContentRenderPhase, rhs: TokenMenuContentRenderPhase) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    enum PanelContainerContext {
        case anchoredPanel
        case anchoredSystemPopover
        case embeddedPreview

        var isAnchoredPresentation: Bool {
            switch self {
            case .anchoredPanel, .anchoredSystemPopover:
                true
            case .embeddedPreview:
                false
            }
        }
    }

    enum LayoutMode: Equatable {
        case measure
        case display(height: CGFloat, allowsScrolling: Bool)
    }

    private enum PanelLayout {
        static let width: CGFloat = 438
    }

    private enum CardRole {
        case standard
        case summary
        case detail

        var minHeight: CGFloat {
            switch self {
            case .standard:
                0
            case .summary:
                92
            case .detail:
                104
            }
        }
    }

    private enum CardBackgroundStyle {
        case glass
        case floating
    }

    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var renderPhase: TokenMenuContentRenderPhase
    let panelContainerContext: PanelContainerContext
    let previewMode: Bool
    let layoutMode: LayoutMode
    let renderPhaseMode: TokenMenuPanelRenderPhaseMode?
    private let panelWidth: CGFloat = Self.preferredPanelWidth
    private let panelCornerRadius: CGFloat = 34

    init(
        store: UsageStore,
        settings: SettingsStore,
        panelContainerContext: PanelContainerContext = .anchoredPanel,
        layoutMode: LayoutMode,
        renderPhaseMode: TokenMenuPanelRenderPhaseMode? = nil,
        previewMode: Bool = false)
    {
        self.store = store
        self.settings = settings
        self.panelContainerContext = panelContainerContext
        self.layoutMode = layoutMode
        self.renderPhaseMode = renderPhaseMode
        self.previewMode = previewMode
        self._renderPhase = State(initialValue: Self.initialRenderPhase(
            layoutMode: layoutMode,
            panelContainerContext: panelContainerContext,
            previewMode: previewMode,
            renderPhaseMode: renderPhaseMode))
    }

    private var strings: AppStrings {
        self.settings.strings
    }

    private var showsSparkQuotaHeroCard: Bool {
        self.store.isSparkQuotaFeatureEnabled
    }

    func quotaMetadataLinkURL(for variant: RemainingQuotaFitnessCardVariant) -> URL? {
        guard variant == .general else { return nil }
        return OpenAIDashboardFetcher.usagePageURL
    }

    private var usesUnifiedCompactPanel: Bool {
        self.settings.menuPanelVersion == .unifiedCompact
    }

    private var usesLiquidGlassContainer: Bool {
        switch self.panelContainerContext {
        case .anchoredPanel:
            true
        case .anchoredSystemPopover:
            false
        case .embeddedPreview:
            self.settings.menuPopupStyle == .liquidGlass
        }
    }

    private var usesSystemPopoverContainer: Bool {
        !self.usesLiquidGlassContainer
    }

    private var showsSystemPopoverPreviewShell: Bool {
        self.panelContainerContext == .embeddedPreview && self.usesSystemPopoverContainer
    }

    private var layoutState: TokenMenuContentLayoutState {
        TokenMenuContentLayoutState(
            orderedModules: self.settings.dashboardModuleOrder,
            showsRemainingQuotaCard: self.settings.showRemainingQuotaCard,
            showsThirtyDayChartCard: self.settings.showThirtyDayChartCard,
            showsRecentTwentyFourHourChartCard: self.settings.showRecentTwentyFourHourChartCard,
            showsMessageActivityCard: self.settings.showMessageActivityCard,
            showsUsageOverviewCard: self.settings.showUsageOverviewCard,
            showsUsageOverviewNumericCard: self.settings.showUsageOverviewNumericCard,
            usageOverviewRowCount: UsageOverviewPresentationBuilder.rowCount(settings: self.settings),
            showsCodeReviewCard: self.settings.showCodeReviewCard,
            showsCreditsCard: self.settings.showCreditsCard,
            showsUsageBreakdownCard: self.settings.showUsageBreakdownCard,
            showsCreditsHistoryCard: self.settings.showCreditsHistoryCard,
            previewMode: self.previewMode)
    }

    private var rootCardSpacing: CGFloat {
        self.usesUnifiedCompactPanel ? 12 : 14
    }

    private var panelHorizontalPadding: CGFloat {
        self.usesUnifiedCompactPanel ? 14 : 16
    }

    private var panelVerticalPadding: CGFloat {
        self.usesUnifiedCompactPanel ? 14 : 18
    }

    private var thirtyDayChartHeight: CGFloat {
        self.usesUnifiedCompactPanel ? 88 : 124
    }

    private var thirtyDayChartCardPadding: CGFloat {
        12
    }

    private var thirtyDayChartCardSpacing: CGFloat {
        self.usesUnifiedCompactPanel ? 6 : 8
    }

    static func panelMetrics(
        store: UsageStore,
        settings: SettingsStore,
        panelContainerContext: PanelContainerContext = .anchoredPanel,
        previewMode: Bool = false,
        availableScreenHeight: CGFloat? = nil)
        -> TokenMenuPanelSizing
    {
        let hostingView = NSHostingView(
            rootView: MenuContent(
                store: store,
                settings: settings,
                panelContainerContext: panelContainerContext,
                layoutMode: .measure,
                previewMode: previewMode))
        let container = NSView(frame: CGRect(x: 0, y: 0, width: Self.preferredPanelWidth, height: 1))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostingView)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Self.preferredPanelWidth),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        container.layoutSubtreeIfNeeded()
        let measuredSize = container.fittingSize
        return TokenMenuPanelSizing.resolve(
            naturalHeight: measuredSize.height,
            availableScreenHeight: availableScreenHeight)
    }

    static func preferredPanelHeight(
        store: UsageStore,
        settings: SettingsStore,
        panelContainerContext: PanelContainerContext = .anchoredPanel,
        previewMode: Bool = false,
        availableScreenHeight: CGFloat? = nil)
        -> CGFloat
    {
        self.panelMetrics(
            store: store,
            settings: settings,
            panelContainerContext: panelContainerContext,
            previewMode: previewMode,
            availableScreenHeight: availableScreenHeight)
            .displayHeight
    }

    static let preferredPanelWidth: CGFloat = PanelLayout.width
    static let defaultNaturalHeight: CGFloat = 960

    static func layoutSignature(
        store: UsageStore,
        settings: SettingsStore,
        popupStyleOverride: MenuPopupStyle? = nil,
        previewMode: Bool = false)
        -> TokenMenuPanelLayoutSignature
    {
        let popupStyle = popupStyleOverride ?? settings.menuPopupStyle
        let heightCacheKey = self.panelHeightCacheKey(
            store: store,
            settings: settings,
            popupStyleOverride: popupStyle,
            previewMode: previewMode)
        let codexQuotaModel = store.remainingQuotaPresentation.codexQuotaModel

        return TokenMenuPanelLayoutSignature(
            heightCacheKey: heightCacheKey,
            menuPanelVersion: settings.menuPanelVersion.rawValue,
            menuPopupStyle: popupStyle.rawValue,
            sections: heightCacheKey.sections,
            usageOverviewRowCount: heightCacheKey.usageOverviewRowCount,
            showsSparkQuotaCard: heightCacheKey.showsSparkQuotaCard,
            hasCodexQuotaData: codexQuotaModel.hasQuotaData,
            sparkHasQuotaData: settings.showRemainingQuotaCard && settings.showSparkQuotaCard && store
                .sparkQuotaHasData,
            showsDashboardError: settings.showRemainingQuotaCard && settings.showSparkQuotaCard
                && !(store.sparkQuotaCardErrorMessage?.isEmpty ?? true),
            showsHistoryError: !(store.lastError?.isEmpty ?? true))
    }

    static func panelHeightCacheKey(
        store: UsageStore,
        settings: SettingsStore,
        popupStyleOverride: MenuPopupStyle? = nil,
        previewMode: Bool = false)
        -> TokenMenuPanelHeightCacheKey
    {
        let popupStyle = popupStyleOverride ?? settings.menuPopupStyle
        let strings = settings.strings
        let usageOverviewRowCount = self.usageOverviewRowCount(
            store: store,
            settings: settings,
            strings: strings)
        let layoutState = TokenMenuContentLayoutState(
            orderedModules: settings.dashboardModuleOrder,
            showsRemainingQuotaCard: settings.showRemainingQuotaCard,
            showsThirtyDayChartCard: settings.showThirtyDayChartCard,
            showsRecentTwentyFourHourChartCard: settings.showRecentTwentyFourHourChartCard,
            showsMessageActivityCard: settings.showMessageActivityCard,
            showsUsageOverviewCard: settings.showUsageOverviewCard,
            showsUsageOverviewNumericCard: settings.showUsageOverviewNumericCard,
            usageOverviewRowCount: usageOverviewRowCount,
            showsCodeReviewCard: settings.showCodeReviewCard,
            showsCreditsCard: settings.showCreditsCard,
            showsUsageBreakdownCard: settings.showUsageBreakdownCard,
            showsCreditsHistoryCard: settings.showCreditsHistoryCard,
            previewMode: previewMode)

        return TokenMenuPanelHeightCacheKey(
            menuPanelVersion: settings.menuPanelVersion.rawValue,
            menuPopupStyle: popupStyle.rawValue,
            sections: layoutState.sections,
            usageOverviewRowCount: usageOverviewRowCount,
            showsSparkQuotaCard: store.isSparkQuotaFeatureEnabled)
    }

    private static func usageOverviewRowCount(
        store: UsageStore,
        settings: SettingsStore,
        strings: AppStrings)
        -> Int
    {
        _ = store
        _ = strings
        return UsageOverviewPresentationBuilder.rowCount(settings: settings)
    }

    private var lowerSecondaryText: Color {
        TokenFloatingCardTheme.secondaryText
    }

    private var lowerTertiaryText: Color {
        TokenFloatingCardTheme.tertiaryText
    }

    private var lowerDividerTint: Color {
        TokenFloatingCardTheme.stroke.opacity(0.64)
    }

    private var moduleHeaderFontSize: CGFloat {
        self.usesUnifiedCompactPanel ? 11.5 : 12
    }

    private var usesDeferredRendering: Bool {
        self.layoutMode != .measure && self.panelContainerContext.isAnchoredPresentation && !self.previewMode
    }

    private var usesLazyStack: Bool {
        switch self.layoutMode {
        case .measure:
            false
        case let .display(_, allowsScrolling):
            allowsScrolling
        }
    }

    private var renderPhaseTaskID: String {
        guard self.usesDeferredRendering else { return "full" }

        return switch self.renderPhaseMode {
        case let .coldStart(signatureIdentity):
            "cold:\(signatureIdentity)"
        case .warmed:
            "warmed"
        case nil:
            "cold:legacy"
        }
    }

    var body: some View {
        let theme = self.settings.menuVisualTheme
        let panelShape = RoundedRectangle(cornerRadius: self.panelCornerRadius, style: .continuous)
        let rootContent = AnyView(
            Group {
                switch self.layoutMode {
                case .measure:
                    self.panelContent
                        .frame(width: self.panelWidth, alignment: .top)

                case let .display(height, allowsScrolling):
                    Group {
                        if allowsScrolling {
                            ScrollView(.vertical, showsIndicators: false) {
                                self.panelContent
                            }
                        } else {
                            self.panelContent
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
                    .frame(width: self.panelWidth, height: height, alignment: .top)
                }
            })

        Group {
            if self.usesLiquidGlassContainer {
                rootContent
                    .background(
                        TokenGlassPanelBackground(
                            cornerRadius: self.panelCornerRadius,
                            tint: TokenMenuTheme.panelGlassTint))
                    .clipShape(panelShape)
            } else if self.showsSystemPopoverPreviewShell {
                rootContent
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96)))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(TokenFloatingCardTheme.stroke.opacity(0.55), lineWidth: 0.8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: TokenMenuTheme.panelShadow.opacity(0.7), radius: 12, x: 0, y: 6)
            } else {
                rootContent
            }
        }
        .id(theme)
        .environment(\.locale, self.strings.locale)
        .task(id: self.renderPhaseTaskID) {
            await self.advanceRenderPhaseIfNeeded()
        }
    }

    private var panelContent: AnyView {
        AnyView(
            self.panelStack
                .padding(.horizontal, self.panelHorizontalPadding)
                .padding(.vertical, self.panelVerticalPadding))
    }

    private var panelStack: AnyView {
        if self.usesLazyStack {
            return AnyView(
                LazyVStack(alignment: .leading, spacing: self.rootCardSpacing) {
                    ForEach(Array(self.layoutState.sections.enumerated()), id: \.offset) { _, section in
                        self.dashboardSectionView(section)
                    }
                })
        }

        return AnyView(
            VStack(alignment: .leading, spacing: self.rootCardSpacing) {
                ForEach(Array(self.layoutState.sections.enumerated()), id: \.offset) { _, section in
                    self.dashboardSectionView(section)
                }
            })
    }

    @ViewBuilder
    private func dashboardSectionView(_ section: TokenMenuContentSection) -> some View {
        let shellPhase = self.shellPhase(for: section)
        let contentPhase = self.contentPhase(for: section)

        if self.renderPhase < shellPhase {
            self.deferredSectionPlaceholder(section)
        } else if self.renderPhase < contentPhase {
            self.sectionShell(section)
        } else {
            self.dashboardSection(section)
        }
    }

    @ViewBuilder
    private func dashboardSection(_ section: TokenMenuContentSection) -> some View {
        switch section {
        case .remainingQuota:
            self.codexQuotaHeroCard
            if self.showsSparkQuotaHeroCard {
                self.sparkQuotaHeroCard
            }
        case .recentTwentyFourHourChart:
            self.recentTwentyFourHourChartCard
        case .messageActivity:
            self.messageActivityCard(renderMode: .chart)
        case .thirtyDayChart:
            self.chartCard
        case .usageOverview:
            self.usageOverviewCard
        case .usageOverviewNumeric:
            self.usageOverviewNumericCard
        case let .summaryPair(first, second):
            self.summaryCardsRow(first: first, second: second)
        case .codeReview:
            self.codeReviewCard
        case .credits:
            self.creditsCard
        case .usageBreakdown:
            self.usageBreakdownCard
        case .creditsHistory:
            self.creditsHistoryCard
        case .footer:
            self.footerBar
        }
    }

    private func shellPhase(for section: TokenMenuContentSection) -> TokenMenuContentRenderPhase {
        guard self.usesDeferredRendering else { return .full }

        switch section {
        case .remainingQuota:
            return .quotaHeroes
        case .messageActivity:
            return .messageActivityShell
        case .usageOverviewNumeric:
            return .usageOverviewNumeric
        case .usageOverview:
            return .summaryShell
        case .thirtyDayChart:
            return .thirtyDayChartShell
        case .recentTwentyFourHourChart:
            return .recentTwentyFourHourChartShell
        case .codeReview,
             .credits,
             .summaryPair,
             .usageBreakdown,
             .creditsHistory:
            return .webCardsShell
        case .footer:
            return .full
        }
    }

    private func contentPhase(for section: TokenMenuContentSection) -> TokenMenuContentRenderPhase {
        guard self.usesDeferredRendering else { return .full }

        switch section {
        case .remainingQuota:
            return .quotaHeroes
        case .messageActivity:
            return .messageActivityChart
        case .usageOverviewNumeric:
            return .usageOverviewNumeric
        case .usageOverview:
            return .summary
        case .thirtyDayChart:
            return .thirtyDayChart
        case .recentTwentyFourHourChart:
            return .recentTwentyFourHourChart
        case .codeReview,
             .credits,
             .summaryPair,
             .usageBreakdown,
             .creditsHistory:
            return .webCards
        case .footer:
            return .full
        }
    }

    @ViewBuilder
    private func sectionShell(_ section: TokenMenuContentSection) -> some View {
        switch section {
        case .messageActivity:
            self.messageActivityCard(renderMode: .shell)
        case .usageOverview:
            self.deferredDetailPlaceholder(
                title: self.strings.totalsTitle,
                systemImage: "sum",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: CGFloat(max(UsageOverviewPresentationBuilder.rowCount(settings: self.settings), 1)) *
                    UsageOverviewLayoutMetrics
                    .detailedRowHeight)
        case .thirtyDayChart:
            self.deferredDetailPlaceholder(
                title: self.strings.lastThirtyDaysTitle,
                systemImage: "calendar",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: self.thirtyDayChartHeight)
        case .recentTwentyFourHourChart:
            self.deferredDetailPlaceholder(
                title: self.strings.recentFortyEightHoursTitle,
                systemImage: "chart.line.uptrend.xyaxis",
                accent: TokenMenuTheme.recentHistoryTint,
                contentHeight: 108)
        case .codeReview:
            self.deferredSummaryPlaceholder(
                title: self.strings.codeReviewTitle,
                systemImage: "checkmark.circle",
                accent: TokenMenuTheme.reviewTint)
        case .credits:
            self.deferredSummaryPlaceholder(
                title: self.strings.quotaCreditsLabel,
                systemImage: "creditcard",
                accent: TokenMenuTheme.creditsTint)
        case let .summaryPair(first, second):
            HStack(alignment: .top, spacing: self.rootCardSpacing) {
                self.deferredSummaryPlaceholder(module: first)
                self.deferredSummaryPlaceholder(module: second)
            }
        case .usageBreakdown:
            self.deferredDetailPlaceholder(
                title: self.strings.usageBreakdownTitle,
                systemImage: "chart.bar.xaxis",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: 118)
        case .creditsHistory:
            self.deferredDetailPlaceholder(
                title: self.strings.creditsHistoryTitle,
                systemImage: "clock",
                accent: TokenMenuTheme.creditsTint,
                contentHeight: 118)
        case .remainingQuota,
             .usageOverviewNumeric,
             .footer:
            self.dashboardSection(section)
        }
    }

    @ViewBuilder
    private func deferredSectionPlaceholder(_ section: TokenMenuContentSection) -> some View {
        switch section {
        case .remainingQuota, .footer:
            EmptyView()
        case .messageActivity:
            self.deferredDetailPlaceholder(
                title: self.strings.messageActivityTitle,
                systemImage: "paperplane",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: MessageActivityCardLayoutMetrics.miniChartHeight + 44)
        case .recentTwentyFourHourChart:
            self.deferredDetailPlaceholder(
                title: self.strings.recentFortyEightHoursTitle,
                systemImage: "chart.line.uptrend.xyaxis",
                accent: TokenMenuTheme.recentHistoryTint,
                contentHeight: 108)
        case .thirtyDayChart:
            self.deferredDetailPlaceholder(
                title: self.strings.lastThirtyDaysTitle,
                systemImage: "calendar",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: self.thirtyDayChartHeight)
        case .usageOverview:
            self.deferredDetailPlaceholder(
                title: self.strings.totalsTitle,
                systemImage: "sum",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: CGFloat(max(UsageOverviewPresentationBuilder.rowCount(settings: self.settings), 1)) *
                    UsageOverviewLayoutMetrics
                    .detailedRowHeight)
        case .usageOverviewNumeric:
            self.deferredDetailPlaceholder(
                title: self.strings.totalsNumericTitle,
                systemImage: "number.square",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: UsageOverviewLayoutMetrics.numericPlaceholderHeight)
        case .codeReview:
            self.deferredSummaryPlaceholder(
                title: self.strings.codeReviewTitle,
                systemImage: "checkmark.circle",
                accent: TokenMenuTheme.reviewTint)
        case .credits:
            self.deferredSummaryPlaceholder(
                title: self.strings.quotaCreditsLabel,
                systemImage: "creditcard",
                accent: TokenMenuTheme.creditsTint)
        case let .summaryPair(first, second):
            HStack(alignment: .top, spacing: self.rootCardSpacing) {
                self.deferredSummaryPlaceholder(module: first)
                self.deferredSummaryPlaceholder(module: second)
            }
        case .usageBreakdown:
            self.deferredDetailPlaceholder(
                title: self.strings.usageBreakdownTitle,
                systemImage: "chart.bar.xaxis",
                accent: TokenMenuTheme.analyticsTint,
                contentHeight: 118)
        case .creditsHistory:
            self.deferredDetailPlaceholder(
                title: self.strings.creditsHistoryTitle,
                systemImage: "clock",
                accent: TokenMenuTheme.creditsTint,
                contentHeight: 118)
        }
    }

    private func deferredSummaryPlaceholder(module: DashboardModule) -> some View {
        switch module {
        case .codeReview:
            return AnyView(
                self.deferredSummaryPlaceholder(
                    title: self.strings.codeReviewTitle,
                    systemImage: "checkmark.circle",
                    accent: TokenMenuTheme.reviewTint))
        case .credits:
            return AnyView(
                self.deferredSummaryPlaceholder(
                    title: self.strings.quotaCreditsLabel,
                    systemImage: "creditcard",
                    accent: TokenMenuTheme.creditsTint))
        default:
            return AnyView(EmptyView())
        }
    }

    private func deferredSummaryPlaceholder(
        title: String,
        systemImage: String,
        accent: Color)
        -> some View
    {
        self.card(accent: accent, role: .summary, backgroundStyle: .floating) {
            VStack(alignment: .leading, spacing: 12) {
                self.moduleHeader(title, systemImage: systemImage)
                Spacer(minLength: 0)
                self.placeholderCapsule(width: 92, height: 30)
                self.placeholderCapsule(width: 116, height: 14, opacity: 0.6)
                    .frame(height: 16, alignment: .leading)
            }
        }
    }

    private func deferredDetailPlaceholder(
        title: String,
        systemImage: String,
        accent: Color,
        contentHeight: CGFloat)
        -> some View
    {
        self.card(
            accent: accent,
            padding: self.thirtyDayChartCardPadding,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: self.thirtyDayChartCardSpacing) {
                self.moduleHeader(title, systemImage: systemImage)
                VStack(alignment: .leading, spacing: 10) {
                    self.placeholderCapsule(width: 160, height: 14, opacity: 0.55)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TokenFloatingCardTheme.track.opacity(0.72))
                        .frame(height: contentHeight)
                        .overlay(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(TokenFloatingCardTheme.stroke.opacity(0.42))
                                .frame(height: 1)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 6)
                        }
                }
            }
        }
    }

    private func placeholderCapsule(width: CGFloat, height: CGFloat, opacity: Double = 0.78) -> some View {
        RoundedRectangle(
            cornerRadius: TokenMenuTheme.chromeCornerRadius(default: height / 2, pixel: min(max(height * 0.28, 3), 5)),
            style: .continuous)
            .fill(TokenFloatingCardTheme.track.opacity(opacity))
            .frame(width: width, height: height)
    }

    private func advanceRenderPhaseIfNeeded() async {
        guard self.usesDeferredRendering else {
            self.renderPhase = .full
            Self.renderLogger.debug("Main panel render phase complete [mode: immediate, phase: full]")
            return
        }

        if self.renderPhaseMode == .warmed {
            self.renderPhase = .full
            Self.renderLogger.debug("Main panel render phase complete [mode: warm-reopen, phase: full]")
            return
        }

        self.renderPhase = .quotaHeroes
        Self.renderLogger.debug("Main panel render phase complete [mode: cold-open, phase: quotaHeroes]")
        await Task.yield()
        guard !Task.isCancelled else { return }

        await self.advanceRenderPhase(to: .usageOverviewNumeric, afterNanoseconds: 40_000_000)
        await self.advanceRenderPhase(to: .messageActivityShell, afterNanoseconds: 80_000_000)
        await self.advanceRenderPhase(to: .messageActivityChart, afterNanoseconds: 420_000_000)
        await self.advanceRenderPhase(to: .summaryShell, afterNanoseconds: 250_000_000)
        await self.advanceRenderPhase(to: .summary, afterNanoseconds: 320_000_000)
        await self.advanceRenderPhase(to: .thirtyDayChartShell, afterNanoseconds: 260_000_000)
        await self.advanceRenderPhase(to: .thirtyDayChart, afterNanoseconds: 420_000_000)
        await self.advanceRenderPhase(to: .recentTwentyFourHourChartShell, afterNanoseconds: 240_000_000)
        await self.advanceRenderPhase(to: .recentTwentyFourHourChart, afterNanoseconds: 520_000_000)
        await self.advanceRenderPhase(to: .webCardsShell, afterNanoseconds: 280_000_000)
        await self.advanceRenderPhase(to: .webCards, afterNanoseconds: 520_000_000)
        await self.advanceRenderPhase(to: .full, afterNanoseconds: 80_000_000)
    }

    private func advanceRenderPhase(
        to phase: TokenMenuContentRenderPhase,
        afterNanoseconds delay: UInt64)
        async
    {
        try? await Task.sleep(nanoseconds: delay)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.18)) {
            self.renderPhase = phase
        }
        Self.renderLogger.debug(
            "Main panel render phase complete [mode: cold-open, phase: \(String(describing: phase))]")
    }

    private static func initialRenderPhase(
        layoutMode: LayoutMode,
        panelContainerContext: PanelContainerContext,
        previewMode: Bool,
        renderPhaseMode: TokenMenuPanelRenderPhaseMode?)
        -> TokenMenuContentRenderPhase
    {
        let shouldDeferRendering = layoutMode != .measure && panelContainerContext == .anchoredPanel && !previewMode
        guard shouldDeferRendering else { return .full }
        if renderPhaseMode == .warmed {
            return .full
        }
        return .quotaHeroes
    }

    private var codexQuotaHeroCard: some View {
        RemainingQuotaFitnessCardView(
            title: self.strings.remainingQuotaTitle,
            themeVariant: .general,
            showsTitle: true,
            cachedBadgeTitle: self.strings.quotaCachedBadge,
            showsCachedBadge: false,
            cachedActionTitle: nil,
            onCachedAction: nil,
            isRefreshing: self.store.isRefreshing,
            accountHeaderText: self.store.remainingQuotaPresentation.codexQuotaModel.accountHeaderText,
            accountPlan: self.store.remainingQuotaPresentation.codexQuotaModel.accountPlan,
            updatedDescription: self.store.remainingQuotaPresentation.codexQuotaModel.updatedDescription,
            metadataLinkURL: self.quotaMetadataLinkURL(for: .general),
            quotaItems: self.store.remainingQuotaPresentation.codexQuotaModel.quotaItems,
            hasQuotaData: self.store.remainingQuotaPresentation.codexQuotaModel.hasQuotaData,
            emptyMessage: self.store.remainingQuotaPresentation.codexQuotaMessage,
            errorMessage: nil,
            strings: self.strings,
            compactMode: self.usesUnifiedCompactPanel)
    }

    private var sparkQuotaHeroCard: some View {
        RemainingQuotaFitnessCardView(
            title: self.strings.sparkQuotaTitle,
            themeVariant: .spark,
            showsTitle: true,
            cachedBadgeTitle: self.strings.quotaCachedBadge,
            showsCachedBadge: self.store.sparkQuotaIsStale,
            cachedActionTitle: self.store.sparkQuotaIsStale ? self.strings.fetchFromSafari : nil,
            onCachedAction: self.store.sparkQuotaIsStale
                ? {
                    Task {
                        await self.store.forceRefreshOpenAIDashboardFromSafari()
                    }
                }
                : nil,
            isRefreshing: self.store.isRefreshing,
            accountHeaderText: nil,
            accountPlan: nil,
            updatedDescription: nil,
            metadataLinkURL: self.quotaMetadataLinkURL(for: .spark),
            quotaItems: self.store.remainingQuotaPresentation.sparkQuotaItems,
            hasQuotaData: self.store.remainingQuotaPresentation.sparkHasQuotaData,
            emptyMessage: self.store.remainingQuotaPresentation.sparkMessage,
            errorMessage: self.store.remainingQuotaPresentation.sparkErrorMessage,
            strings: self.strings,
            compactMode: self.usesUnifiedCompactPanel)
    }

    private var codeReviewCard: some View {
        self.secondarySummaryCard(
            title: self.strings.codeReviewTitle,
            systemImage: "checkmark.circle",
            accent: TokenMenuTheme.reviewTint,
            valueText: self.store.codeReviewCardPresentation?.valueText ?? "--",
            detailText: self.store.codeReviewCardPresentation?.detailText ?? self.strings.noCodeReviewData)
    }

    private var creditsCard: some View {
        self.secondarySummaryCard(
            title: self.strings.quotaCreditsLabel,
            systemImage: "creditcard",
            accent: TokenMenuTheme.creditsTint,
            valueText: self.store.creditsCardPresentation?.valueText ?? "--",
            detailText: self.store.creditsCardPresentation?.detailText ?? self.strings.noCreditsHistoryData)
    }

    private func summaryCardsRow(first: DashboardModule, second: DashboardModule) -> some View {
        HStack(alignment: .top, spacing: self.rootCardSpacing) {
            self.summaryCard(for: first)
            self.summaryCard(for: second)
        }
    }

    @ViewBuilder
    private func summaryCard(for module: DashboardModule) -> some View {
        switch module {
        case .codeReview:
            self.codeReviewCard
        case .credits:
            self.creditsCard
        default:
            EmptyView()
        }
    }

    private var usageBreakdownCard: some View {
        self.card(
            accent: TokenMenuTheme.analyticsTint,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: 10) {
                self.moduleHeader(self.strings.usageBreakdownTitle, systemImage: "chart.bar.xaxis")

                UsageBreakdownCardView(
                    breakdown: self.store.usageBreakdownPresentation,
                    strings: self.strings,
                    compact: false,
                    usesFloatingStyle: true,
                    interactiveSelectionEnabled: !self.usesDeferredRendering || self.renderPhase >= .full)
            }
        }
    }

    private var creditsHistoryCard: some View {
        self.card(
            accent: TokenMenuTheme.creditsTint,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: 10) {
                self.moduleHeader(self.strings.creditsHistoryTitle, systemImage: "clock")

                CreditsHistoryCardView(
                    breakdown: self.store.creditsHistoryPresentation,
                    strings: self.strings,
                    compact: false,
                    usesFloatingStyle: true,
                    interactiveSelectionEnabled: !self.usesDeferredRendering || self.renderPhase >= .full)
            }
        }
    }

    private var chartCard: some View {
        let model = self.thirtyDayChartModel
        let scale = thirtyDayChartScale(for: model)

        return self.card(
            accent: TokenMenuTheme.analyticsTint,
            padding: self.thirtyDayChartCardPadding,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: self.thirtyDayChartCardSpacing) {
                self.moduleHeader(self.strings.lastThirtyDaysTitle, systemImage: "calendar")

                Chart(model.bars) { bar in
                    let displayedValue = thirtyDayDisplayedBarValue(for: bar.value, scale: scale)
                    let isPeak = model.peakDayID == bar.day.id && bar.value > 0

                    dashboardThirtyDayBarMarks(
                        date: bar.day.date,
                        rawValue: bar.value,
                        displayedValue: displayedValue,
                        isPeak: isPeak,
                        scale: scale,
                        usesFloatingLowerCards: true,
                        peakBubbleText: isPeak ? self.strings.thirtyDayPeakTokenText(bar.value) : nil)
                }
                .chartYScale(domain: 0...scale.topValue)
                .chartPlotStyle { plot in
                    plot
                        .padding(.top, ThirtyDayChartStyle.peakLabelReservedHeight)
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: scale.axisValues) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.45, dash: [3, 5]))
                            .foregroundStyle(
                                chartGridTint(usesFloatingLowerCards: true)
                                    .opacity(0.72))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: model.axisDates) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.35, dash: [2, 6]))
                            .foregroundStyle(
                                chartGridTint(usesFloatingLowerCards: true)
                                    .opacity(0.42))
                    }
                }
                .chartLegend(.hidden)
                .frame(height: self.thirtyDayChartPlotHeight)

                TokenChartBottomAxisStrip(
                    markers: model.axisMarkers,
                    frameHeight: ThirtyDayChartStyle.axisLabelReservedHeight,
                    rowCenterY: ThirtyDayChartStyle.axisLabelTopGap + (ThirtyDayChartStyle.axisLabelHeight / 2),
                    labelWidth: { marker in
                        dashboardThirtyDayAxisLabelWidth(for: marker.text)
                    },
                    label: { marker, alignment in
                        dashboardThirtyDayAxisLabel(
                            text: marker.text,
                            alignment: alignment,
                            usesFloatingLowerCards: true)
                    })

                if let lastError = self.store.lastError, !lastError.isEmpty {
                    self.cardSectionDivider

                    Label(lastError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(TokenMenuTheme.warningText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var recentTwentyFourHourChartCard: some View {
        self.card(
            accent: TokenMenuTheme.recentHistoryTint,
            padding: self.thirtyDayChartCardPadding,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: self.thirtyDayChartCardSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    self.moduleHeader(self.strings.recentFortyEightHoursTitle, systemImage: "chart.line.uptrend.xyaxis")

                    Spacer(minLength: 12)

                    Text(self.store.recentFortyEightHourPresentation.headerTotalText)
                        .font(.system(size: self.moduleHeaderFontSize, weight: .semibold))
                        .foregroundStyle(self.recentFortyEightHourHeaderTotalStyle)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }

                RecentFortyEightHourBarChartCardView(
                    hours: self.store.recentFortyEightHourPresentation.hours,
                    strings: self.strings,
                    compact: self.usesUnifiedCompactPanel,
                    usesFloatingStyle: true)
            }
        }
    }

    private var recentFortyEightHourHeaderTotalStyle: AnyShapeStyle {
        if self.colorScheme == .dark {
            return AnyShapeStyle(TokenFloatingCardTheme.valueGradient(for: .input))
        }
        return AnyShapeStyle(TokenFloatingCardTheme.valueColor(for: .input).opacity(0.96))
    }

    private var usageOverviewCard: some View {
        self.card(
            accent: TokenMenuTheme.analyticsTint,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: 10) {
                self.moduleHeader(self.strings.totalsTitle, systemImage: "sum")

                UsageOverviewCardView(
                    rows: self.store.usageOverviewRowsPresentation,
                    strings: self.strings,
                    usesFloatingStyle: true,
                    compactMode: false)
            }
        }
        .zIndex(20)
    }

    private var usageOverviewNumericCard: some View {
        self.card(
            accent: TokenMenuTheme.analyticsTint,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: 10) {
                self.moduleHeader(self.strings.totalsNumericTitle, systemImage: "number.square")

                UsageOverviewNumericCardView(
                    items: self.store.usageOverviewNumericItemsPresentation.map { item in
                        UsageOverviewNumericCardView.Item(
                            id: item.id,
                            title: item.title,
                            primaryAmountText: item.primaryAmountText,
                            primaryUnitText: item.primaryUnitText,
                            secondaryLabelText: item.secondaryLabelText,
                            secondaryAmountText: item.secondaryAmountText,
                            secondaryUnitText: item.secondaryUnitText,
                            accessibilityText: item.accessibilityText)
                    })
            }
        }
    }

    private func messageActivityCard(renderMode: MessageActivityCardView.RenderMode) -> some View {
        self.card(
            accent: TokenMenuTheme.analyticsTint,
            role: .detail,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: 8) {
                self.moduleHeader(self.strings.messageActivityTitle, systemImage: "paperplane")

                MessageActivityCardView(
                    days: self.store.messageActivityPresentation.days,
                    todayTotal: self.store.messageActivityPresentation.todayTotal,
                    sevenDayTotal: self.store.messageActivityPresentation.sevenDayTotal,
                    thirtyDayTotal: self.store.messageActivityPresentation.thirtyDayTotal,
                    cumulativeTotal: self.store.messageActivityPresentation.cumulativeTotal,
                    strings: self.strings,
                    usesFloatingStyle: true,
                    renderMode: renderMode)
            }
        }
    }

    private var thirtyDayChartModel: ThirtyDayChartModel {
        let days = self.store.thirtyDayChartDaysPresentation.compactMap { stats -> ThirtyDayChartDay? in
            guard let date = stats.chartDate else { return nil }
            return ThirtyDayChartDay(stats: stats, date: date)
        }
        let bars = days.map { day in
            ThirtyDayChartBar(day: day, value: day.stats.totalTokens)
        }

        let axisDates = self.thirtyDayAxisDates(for: days)
        let axisMarkers = self.thirtyDayAxisMarkers(for: days, axisDates: axisDates)
        let peakDayID = ThirtyDayChartPeakResolver.peakDayID(from: days.map(\.stats))

        return ThirtyDayChartModel(
            days: days,
            bars: bars,
            axisDates: axisDates,
            axisMarkers: axisMarkers,
            peakDayID: peakDayID)
    }

    private func moduleHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(TokenMenuTheme.labelFont(size: self.moduleHeaderFontSize, weight: .semibold))
            .foregroundStyle(self.lowerSecondaryText)
            .labelStyle(.titleAndIcon)
            .imageScale(.small)
            .lineLimit(1)
            .layoutPriority(1)
    }

    private func secondarySummaryCard(
        title: String,
        systemImage: String,
        accent: Color,
        valueText: String,
        detailText: String)
        -> some View
    {
        let isEmptyState = valueText == "--"
        return self.card(
            accent: accent,
            role: .summary,
            backgroundStyle: .floating)
        {
            VStack(alignment: .leading, spacing: 12) {
                self.moduleHeader(title, systemImage: systemImage)

                Spacer(minLength: 0)

                Text(valueText)
                    .font(TokenMenuTheme.metricFont(size: 34, weight: .bold))
                    .foregroundStyle(accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                self.secondarySummaryDetailLine(
                    detailText,
                    tint: isEmptyState ? self.lowerSecondaryText : self.lowerTertiaryText)
            }
        }
    }

    private func secondarySummaryDetailLine(_ text: String, tint: Color) -> some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = trimmed.isEmpty ? " " : trimmed
        return Text(displayText)
            .font(TokenMenuTheme.labelFont(size: 11.5, weight: .regular))
            .foregroundStyle(tint)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(height: 16, alignment: .leading)
            .opacity(trimmed.isEmpty ? 0 : 1)
    }

    private var cardSectionDivider: some View {
        Rectangle()
            .fill(self.lowerDividerTint)
            .frame(height: 1)
    }
}

extension MenuContent {
    private var thirtyDayChartPlotHeight: CGFloat {
        max(self.thirtyDayChartHeight - ThirtyDayChartStyle.axisLabelReservedHeight, 1)
    }

    private func thirtyDayAxisDates(for days: [ThirtyDayChartDay]) -> [Date] {
        guard !days.isEmpty else { return [] }
        if days.count <= 2 { return days.map(\.date) }

        let desiredCount = min(5, days.count)
        let step = max((days.count + desiredCount - 3) / (desiredCount - 1), 1)

        var dates = Array(stride(from: 0, to: days.count, by: step)).map { days[$0].date }
        if let last = days.last?.date,
           dates.last.map({ !Calendar.current.isDate($0, inSameDayAs: last) }) ?? true
        {
            dates.append(last)
        }
        return dates
    }

    private func thirtyDayAxisMarkers(for days: [ThirtyDayChartDay], axisDates: [Date]) -> [TokenChartAxisMarker] {
        guard !days.isEmpty else { return [] }

        return axisDates.compactMap { date in
            guard let index = days.firstIndex(where: { $0.date == date }) else { return nil }
            let normalizedX = CGFloat(index) / CGFloat(max(days.count - 1, 1))
            let priority: TokenChartAxisMarker.Priority = if index == 0 || index == days.count - 1 {
                .boundary
            } else {
                .normal
            }

            return TokenChartAxisMarker(
                id: "\(Int(date.timeIntervalSince1970))",
                text: self.thirtyDayAxisLabelText(for: date),
                normalizedX: normalizedX,
                priority: priority)
        }
    }

    private func thirtyDayAxisLabelText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = self.strings.locale
        formatter.calendar = Calendar.current
        formatter.timeZone = Calendar.current.timeZone
        formatter.setLocalizedDateFormatFromTemplate("M/d")
        return formatter.string(from: date)
    }

    private var footerBar: some View {
        self.card(
            accent: Color.white.opacity(0.02),
            padding: 8,
            backgroundStyle: .floating)
        {
            HStack(spacing: 8) {
                self.actionButton(title: self.strings.refreshNow) {
                    Task {
                        await self.store.refresh(forceDashboard: true)
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])

                self.actionButton(title: self.strings.rebuildCache) {
                    Task {
                        await self.store.rebuildCache()
                    }
                }

                self.actionButton(title: self.strings.settings) {
                    TokenSettingsWindowCoordinator.requestOpenSettings()
                }

                Spacer(minLength: 0)

                self.actionButton(title: self.strings.quit) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    private func card(
        accent: Color,
        padding: CGFloat = 12,
        role: CardRole = .standard,
        backgroundStyle: CardBackgroundStyle = .floating,
        @ViewBuilder content: () -> some View) -> some View
    {
        let effectivePadding = padding
        let cornerRadius: CGFloat = if backgroundStyle == .floating { 16 } else { 24 }
        let paddedContent = VStack(alignment: .leading, spacing: 0, content: content)
            .padding(effectivePadding)

        return Group {
            switch role {
            case .standard:
                paddedContent

            case .summary, .detail:
                paddedContent
                    .frame(
                        maxWidth: .infinity,
                        minHeight: role.minHeight,
                        alignment: .topLeading)
            }
        }
        .background {
            switch backgroundStyle {
            case .glass:
                TokenGlassCardBackground(cornerRadius: 24, tint: accent)
            case .floating:
                TokenFloatingCardBackground(
                    cornerRadius: cornerRadius,
                    tint: accent,
                    emphasis: .subtle)
            }
        }
    }

    private func actionButton(
        title: String,
        style: PanelButtonChrome.Style = .footerSubdued,
        action: @escaping () -> Void) -> some View
    {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PanelButtonChrome(style: style))
    }
}

private struct PanelButtonChrome: ButtonStyle {
    enum Style {
        case footerSubdued

        var cornerRadius: CGFloat {
            TokenMenuTheme.chromeCornerRadius(default: 10, pixel: 6)
        }

        var fontWeight: Font.Weight {
            .medium
        }

        var foregroundTint: Color {
            TokenMenuTheme.footerButtonText
        }

        var highlightedForegroundTint: Color {
            TokenMenuTheme.footerButtonHoverText
        }

        var horizontalPadding: CGFloat {
            10
        }

        var verticalPadding: CGFloat {
            5
        }

        var minimumHeight: CGFloat {
            28
        }

        var pressedScale: CGFloat {
            0.985
        }
    }

    let style: Style

    func makeBody(configuration: Configuration) -> some View {
        PanelButtonChromeBody(configuration: configuration, style: self.style)
    }
}

private struct PanelButtonChromeBody: View {
    let configuration: ButtonStyleConfiguration
    let style: PanelButtonChrome.Style

    @State private var isHovered = false

    private var isHighlighted: Bool {
        self.isHovered || self.configuration.isPressed
    }

    var body: some View {
        self.configuration.label
            .font(TokenMenuTheme.labelFont(size: 12, weight: self.style.fontWeight))
            .foregroundStyle(self.isHighlighted ? self.style.highlightedForegroundTint : self.style.foregroundTint)
            .lineLimit(1)
            .padding(.horizontal, self.style.horizontalPadding)
            .padding(.vertical, self.style.verticalPadding)
            .frame(minHeight: self.style.minimumHeight)
            .background {
                FooterPanelButtonBackground(
                    cornerRadius: self.style.cornerRadius,
                    isHovered: self.isHovered,
                    isPressed: self.configuration.isPressed)
            }
            .contentShape(RoundedRectangle(cornerRadius: self.style.cornerRadius, style: .continuous))
            .scaleEffect(self.configuration.isPressed ? self.style.pressedScale : 1)
            .animation(.easeOut(duration: 0.12), value: self.isHovered)
            .animation(.easeOut(duration: 0.12), value: self.configuration.isPressed)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
}

private struct FooterPanelButtonBackground: View {
    let cornerRadius: CGFloat
    let isHovered: Bool
    let isPressed: Bool

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    private var fillColor: Color {
        if self.isPressed {
            return TokenMenuTheme.footerButtonPressedFill
        }
        if self.isHovered {
            return TokenMenuTheme.footerButtonHoverFill
        }
        return .clear
    }

    private var strokeColor: Color {
        if self.isPressed {
            return TokenMenuTheme.footerButtonPressedStroke
        }
        if self.isHovered {
            return TokenMenuTheme.footerButtonHoverStroke
        }
        return .clear
    }

    private var glowOpacity: Double {
        if self.isPressed {
            return 1
        }
        if self.isHovered {
            return 0.74
        }
        return 0
    }

    var body: some View {
        self.shape
            .fill(self.fillColor)
            .overlay {
                self.shape
                    .fill(
                        RadialGradient(
                            colors: [
                                TokenMenuTheme.footerButtonGlow.opacity(self.glowOpacity),
                                Color.clear,
                            ],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 84))
            }
            .overlay {
                self.shape
                    .stroke(self.strokeColor, lineWidth: TokenMenuTheme.usesPixelChrome ? 1.25 : 0.75)
            }
            .shadow(
                color: TokenMenuTheme.usesPixelChrome
                    ? TokenMenuTheme.pixelShadow.opacity(self.glowOpacity == 0 ? 0 : 0.52)
                    : Color.clear,
                radius: 0,
                x: TokenMenuTheme.usesPixelChrome && self.glowOpacity > 0 ? 2 : 0,
                y: TokenMenuTheme.usesPixelChrome && self.glowOpacity > 0 ? 2 : 0)
    }
}
