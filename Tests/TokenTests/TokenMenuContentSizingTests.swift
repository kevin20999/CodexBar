import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

@MainActor
final class TokenMenuContentSizingTests: XCTestCase {
    func test_usageOverviewLayoutMetricsReserveSpaceForTwoCompactSummaryLines() {
        XCTAssertEqual(UsageOverviewLayoutMetrics.detailedRowHeight, 64)
        XCTAssertEqual(UsageOverviewLayoutMetrics.numericGridSpacing, 10)
        XCTAssertEqual(UsageOverviewLayoutMetrics.numericCardMinHeight, 100)
        XCTAssertEqual(UsageOverviewLayoutMetrics.numericPlaceholderHeight, 210)
    }

    func test_layoutStateMatchesRequestedFirstInstallModules() {
        let layoutState = TokenMenuContentLayoutState(
            orderedModules: DashboardModule.defaultOrder,
            showsRemainingQuotaCard: true,
            showsThirtyDayChartCard: true,
            showsRecentTwentyFourHourChartCard: true,
            showsMessageActivityCard: true,
            showsUsageOverviewCard: true,
            showsUsageOverviewNumericCard: false,
            usageOverviewRowCount: 4,
            showsCodeReviewCard: false,
            showsCreditsCard: false,
            showsUsageBreakdownCard: false,
            showsCreditsHistoryCard: false,
            previewMode: false)

        XCTAssertEqual(
            layoutState.sections,
            [.remainingQuota, .recentTwentyFourHourChart, .messageActivity, .thirtyDayChart, .usageOverview, .footer])
    }

    func test_layoutStateFollowsCustomDashboardOrderAndPairsAdjacentSummaryCards() {
        let layoutState = TokenMenuContentLayoutState(
            orderedModules: [
                .credits,
                .codeReview,
                .remainingQuota,
                .usageOverview,
                .recentFortyEightHours,
                .messageActivity,
                .lastThirtyDays,
                .usageBreakdown,
                .creditsHistory,
            ],
            showsRemainingQuotaCard: true,
            showsThirtyDayChartCard: true,
            showsRecentTwentyFourHourChartCard: true,
            showsMessageActivityCard: true,
            showsUsageOverviewCard: true,
            showsUsageOverviewNumericCard: false,
            usageOverviewRowCount: 2,
            showsCodeReviewCard: true,
            showsCreditsCard: true,
            showsUsageBreakdownCard: true,
            showsCreditsHistoryCard: true,
            previewMode: false)

        XCTAssertEqual(
            layoutState.sections,
            [
                .summaryPair(first: .credits, second: .codeReview),
                .remainingQuota,
                .usageOverview,
                .recentTwentyFourHourChart,
                .messageActivity,
                .thirtyDayChart,
                .usageBreakdown,
                .creditsHistory,
                .footer,
            ])
    }

    func test_layoutStateSeparatesSummaryCardsWhenNotAdjacent() {
        let layoutState = TokenMenuContentLayoutState(
            orderedModules: [
                .credits,
                .remainingQuota,
                .codeReview,
                .usageOverview,
                .usageOverviewNumeric,
            ],
            showsRemainingQuotaCard: true,
            showsThirtyDayChartCard: false,
            showsRecentTwentyFourHourChartCard: false,
            showsMessageActivityCard: false,
            showsUsageOverviewCard: true,
            showsUsageOverviewNumericCard: false,
            usageOverviewRowCount: 1,
            showsCodeReviewCard: true,
            showsCreditsCard: true,
            showsUsageBreakdownCard: false,
            showsCreditsHistoryCard: false,
            previewMode: true)

        XCTAssertEqual(
            layoutState.sections,
            [
                .credits,
                .remainingQuota,
                .codeReview,
                .usageOverview,
            ])
    }

    func test_layoutStateShowsUsageOverviewNumericWhenEnabled() {
        let layoutState = TokenMenuContentLayoutState(
            orderedModules: [
                .remainingQuota,
                .usageOverviewNumeric,
                .usageOverview,
            ],
            showsRemainingQuotaCard: true,
            showsThirtyDayChartCard: false,
            showsRecentTwentyFourHourChartCard: false,
            showsMessageActivityCard: false,
            showsUsageOverviewCard: true,
            showsUsageOverviewNumericCard: true,
            usageOverviewRowCount: 1,
            showsCodeReviewCard: false,
            showsCreditsCard: false,
            showsUsageBreakdownCard: false,
            showsCreditsHistoryCard: false,
            previewMode: true)

        XCTAssertEqual(
            layoutState.sections,
            [
                .remainingQuota,
                .usageOverviewNumeric,
                .usageOverview,
            ])
    }

    func test_panelHeightCacheKeyChangesWhenPopupStyleChanges() throws {
        let context = try self.makeContext()
        let liquidGlassKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings,
            previewMode: false)

        context.settings.menuPopupStyle = .systemPopover

        let systemPopoverKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings,
            previewMode: false)

        XCTAssertNotEqual(liquidGlassKey, systemPopoverKey)
        XCTAssertNotEqual(liquidGlassKey.storageKey, systemPopoverKey.storageKey)
    }

    func test_panelMetricsGrowAndShrinkWithVisibleModules() throws {
        let context = try self.makeContext()
        let defaultMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.settings.showCodeReviewCard = true
        context.settings.showCreditsCard = true
        context.settings.showUsageBreakdownCard = true
        context.settings.showCreditsHistoryCard = true

        let expandedMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertGreaterThan(expandedMetrics.naturalHeight, defaultMetrics.naturalHeight)

        context.settings.showCodeReviewCard = false
        context.settings.showCreditsCard = false
        context.settings.showUsageBreakdownCard = false
        context.settings.showCreditsHistoryCard = false

        let collapsedMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertLessThan(collapsedMetrics.naturalHeight, expandedMetrics.naturalHeight)
        XCTAssertEqual(collapsedMetrics.displayHeight, defaultMetrics.displayHeight)
    }

    func test_panelMetricsShrinkWhenRecentTwentyFourHourChartIsHidden() throws {
        let context = try self.makeContext()

        let defaultMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.settings.showRecentTwentyFourHourChartCard = false

        let hiddenMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertLessThan(hiddenMetrics.naturalHeight, defaultMetrics.naturalHeight)
    }

    func test_panelMetricsShrinkWhenMessageActivityCardIsHidden() throws {
        let context = try self.makeContext()

        let defaultMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.settings.showMessageActivityCard = false

        let hiddenMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertLessThan(hiddenMetrics.naturalHeight, defaultMetrics.naturalHeight)
    }

    func test_panelMetricsGrowWhenUsageOverviewNumericCardIsVisible() throws {
        let context = try self.makeContext()

        let defaultMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.settings.showUsageOverviewNumericCard = true

        let expandedMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertGreaterThan(expandedMetrics.naturalHeight, defaultMetrics.naturalHeight)
    }

    func test_panelMetricsKeepSameHeightAcrossRecentFortyEightHourChartStyles() throws {
        let context = try self.makeContext()

        context.settings.recentFortyEightHourChartStyle = .bars
        let barMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.settings.recentFortyEightHourChartStyle = .wave
        let waveMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertEqual(barMetrics.naturalHeight, waveMetrics.naturalHeight, accuracy: 1)
        XCTAssertEqual(barMetrics.displayHeight, waveMetrics.displayHeight, accuracy: 1)
    }

    func test_panelMetricsCapHeightAndEnableScrollingWhenScreenIsTight() throws {
        let context = try self.makeContext()
        context.settings.showCodeReviewCard = true
        context.settings.showCreditsCard = true
        context.settings.showUsageBreakdownCard = true
        context.settings.showCreditsHistoryCard = true

        let unconstrained = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)
        let constrained = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: unconstrained.naturalHeight - 40)

        XCTAssertTrue(constrained.allowsScrolling)
        XCTAssertLessThan(constrained.displayHeight, unconstrained.displayHeight)
        XCTAssertEqual(
            constrained.displayHeight,
            unconstrained.naturalHeight - 40 - TokenMenuPanelSizing.screenMargin,
            accuracy: 1)
    }

    func test_previewMetricsOmitFooterHeight() throws {
        let context = try self.makeContext()

        let anchoredMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)
        let previewMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .embeddedPreview,
            previewMode: true,
            availableScreenHeight: nil)

        XCTAssertLessThan(previewMetrics.naturalHeight, anchoredMetrics.naturalHeight)
        XCTAssertFalse(previewMetrics.allowsScrolling)
    }

    func test_panelMetricsGrowWhenSparkQuotaCardStructureBecomesVisible() throws {
        let context = try self.makeContext()
        context.settings.showSparkQuotaCard = false

        let defaultMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.settings.showSparkQuotaCard = true

        let sparkMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertGreaterThan(sparkMetrics.naturalHeight, defaultMetrics.naturalHeight)
    }

    func test_panelMetricsGrowWhenQuotaHeroNeedsStatusFooter() throws {
        let context = try self.makeContext()
        context.settings.showSparkQuotaCard = false

        let dataMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.store.codexQuotaSnapshot = nil
        context.store.codexQuotaErrorMessage = "Request failed"

        let errorMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertGreaterThan(errorMetrics.naturalHeight, dataMetrics.naturalHeight)
    }

    func test_panelMetricsStayStableWhenQuotaHeroesRefresh() throws {
        let context = try self.makeContext()
        context.settings.showSparkQuotaCard = true
        context.store.codexQuotaSnapshot = CodexQuotaSnapshot(
            primary: context.store.codexQuotaSnapshot?.primary,
            secondary: context.store.codexQuotaSnapshot?.secondary,
            sparkPrimary: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondary: RateWindow(
                usedPercent: 18,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            updatedAt: Date(),
            accountEmail: "person@example.com",
            accountPlan: "Pro")

        let idleMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        context.store.isRefreshing = true

        let refreshingMetrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        XCTAssertEqual(refreshingMetrics.naturalHeight, idleMetrics.naturalHeight, accuracy: 1)
    }

    func test_panelMetricsIgnoreSparkQuotaCardWhenSparkToggleIsOff() throws {
        let baselineContext = try self.makeContext()
        baselineContext.settings.showSparkQuotaCard = false
        let baselineMetrics = MenuContent.panelMetrics(
            store: baselineContext.store,
            settings: baselineContext.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)

        let context = try self.makeContext()
        context.settings.showSparkQuotaCard = false
        context.store.codexQuotaSnapshot = CodexQuotaSnapshot(
            primary: context.store.codexQuotaSnapshot?.primary,
            secondary: context.store.codexQuotaSnapshot?.secondary,
            sparkPrimary: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondary: RateWindow(
                usedPercent: 18,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            updatedAt: Date(),
            accountEmail: "person@example.com",
            accountPlan: "Pro")

        let metrics = MenuContent.panelMetrics(
            store: context.store,
            settings: context.settings,
            panelContainerContext: .anchoredPanel,
            previewMode: false,
            availableScreenHeight: nil)
        let signature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        XCTAssertFalse(signature.showsSparkQuotaCard)
        XCTAssertFalse(signature.sparkHasQuotaData)
        XCTAssertEqual(metrics.naturalHeight, baselineMetrics.naturalHeight, accuracy: 1)
    }

    func test_quotaMetadataLinkURLUsesCodexDashboardForGeneralCardOnly() throws {
        let context = try self.makeContext()
        let content = MenuContent(
            store: context.store,
            settings: context.settings,
            layoutMode: .measure)

        XCTAssertEqual(
            content.quotaMetadataLinkURL(for: .general)?.absoluteString,
            "https://chatgpt.com/codex/settings/usage")
        XCTAssertNil(content.quotaMetadataLinkURL(for: .spark))
    }

    func test_layoutSignatureChangesWhenUsageOverviewRowCountChanges() throws {
        let context = try self.makeContext()

        let defaultSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        context.settings.showTodayUsageCard = false
        context.settings.showSevenDayUsageCard = false
        context.settings.showThirtyDayUsageCard = false

        let collapsedSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        XCTAssertNotEqual(defaultSignature, collapsedSignature)
        XCTAssertGreaterThan(defaultSignature.usageOverviewRowCount, collapsedSignature.usageOverviewRowCount)
    }

    func test_layoutSignatureChangesWhenSparkQuotaDataArrives() throws {
        let context = try self.makeContext()

        let defaultSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)
        let defaultHeightCacheKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings)

        context.store.codexQuotaSnapshot = CodexQuotaSnapshot(
            primary: context.store.codexQuotaSnapshot?.primary,
            secondary: context.store.codexQuotaSnapshot?.secondary,
            sparkPrimary: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondary: RateWindow(
                usedPercent: 18,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            updatedAt: Date(),
            accountEmail: "person@example.com",
            accountPlan: "Pro")

        let sparkSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)
        let sparkHeightCacheKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings)

        XCTAssertNotEqual(defaultSignature, sparkSignature)
        XCTAssertTrue(defaultSignature.showsSparkQuotaCard)
        XCTAssertTrue(sparkSignature.showsSparkQuotaCard)
        XCTAssertEqual(defaultHeightCacheKey, sparkHeightCacheKey)
    }

    func test_layoutSignatureIgnoresSparkQuotaDataWhenSparkToggleIsOff() throws {
        let context = try self.makeContext()
        context.settings.showSparkQuotaCard = false

        let defaultSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        context.store.codexQuotaSnapshot = CodexQuotaSnapshot(
            primary: context.store.codexQuotaSnapshot?.primary,
            secondary: context.store.codexQuotaSnapshot?.secondary,
            sparkPrimary: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondary: RateWindow(
                usedPercent: 18,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            updatedAt: Date(),
            accountEmail: "person@example.com",
            accountPlan: "Pro")

        let sparkSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        XCTAssertEqual(defaultSignature, sparkSignature)
        XCTAssertFalse(sparkSignature.showsSparkQuotaCard)
        XCTAssertFalse(sparkSignature.sparkHasQuotaData)
    }

    func test_panelHeightCacheKeyIgnoresDynamicQuotaAndErrorState() throws {
        let context = try self.makeContext()
        context.settings.openAIWebAccessEnabled = true

        let defaultHeightCacheKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings)

        context.store.codexQuotaSnapshot = nil
        context.store.openAIDashboard = OpenAIDashboardSnapshot(
            signedInEmail: "person@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: nil,
            secondaryLimit: nil,
            sparkPrimaryLimit: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondaryLimit: RateWindow(
                usedPercent: 18,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            creditsRemaining: nil,
            accountPlan: "Plus",
            updatedAt: Date())
        context.store.openAIDashboardDisplayState = .realError(message: "browser unavailable", requiresLogin: false)
        context.store.lastError = "history failed"

        let changedHeightCacheKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings)

        XCTAssertEqual(defaultHeightCacheKey, changedHeightCacheKey)
    }

    func test_panelHeightCacheKeyChangesWhenSparkStructureChanges() throws {
        let context = try self.makeContext()
        context.settings.showSparkQuotaCard = false

        let defaultHeightCacheKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings)

        context.settings.showSparkQuotaCard = true

        let changedHeightCacheKey = MenuContent.panelHeightCacheKey(
            store: context.store,
            settings: context.settings)

        XCTAssertNotEqual(defaultHeightCacheKey, changedHeightCacheKey)
        XCTAssertFalse(defaultHeightCacheKey.showsSparkQuotaCard)
        XCTAssertTrue(changedHeightCacheKey.showsSparkQuotaCard)
    }

    func test_renderPhaseResolverReturnsWarmModeForMatchingWarmedSignature() throws {
        let context = try self.makeContext()
        let signature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        let openKind = TokenMenuPanelRenderPhaseResolver.openKind(
            signature: signature,
            warmedSignature: signature)
        let renderPhaseMode = TokenMenuPanelRenderPhaseResolver.renderPhaseMode(
            signature: signature,
            warmedSignature: signature)

        XCTAssertEqual(openKind, .warmReopen)
        XCTAssertEqual(renderPhaseMode, .warmed)
    }

    func test_renderPhaseResolverReturnsColdModeForNewSignature() throws {
        let context = try self.makeContext()
        let defaultSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        context.settings.showTodayUsageCard = false
        let changedSignature = MenuContent.layoutSignature(
            store: context.store,
            settings: context.settings)

        let openKind = TokenMenuPanelRenderPhaseResolver.openKind(
            signature: changedSignature,
            warmedSignature: defaultSignature)
        let renderPhaseMode = TokenMenuPanelRenderPhaseResolver.renderPhaseMode(
            signature: changedSignature,
            warmedSignature: defaultSignature)

        XCTAssertEqual(openKind, .coldOpen)
        XCTAssertEqual(
            renderPhaseMode,
            .coldStart(signatureIdentity: changedSignature.renderPhaseIdentity))
    }

    private func makeContext() throws -> TokenMenuSizingTestContext {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: TokenMenuSizingLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let sandbox = try TokenMenuSizingSandbox()
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: TokenMenuSizingDashboardProvider(),
            startupRefresh: false)
        store.codexQuotaSnapshot = CodexQuotaSnapshot(
            primary: RateWindow(
                usedPercent: 44,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            secondary: RateWindow(
                usedPercent: 12,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkPrimary: nil,
            sparkSecondary: nil,
            updatedAt: Date(),
            accountEmail: "person@example.com",
            accountPlan: "Pro")

        return TokenMenuSizingTestContext(settings: settings, store: store)
    }
}

private struct TokenMenuSizingTestContext {
    let settings: SettingsStore
    let store: UsageStore
}

private struct TokenMenuSizingSandbox {
    let root: URL
    let fileURL: URL

    init() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.root = root
        self.fileURL = root.appendingPathComponent("token_stats.json", isDirectory: false)
    }
}

@MainActor
private final class TokenMenuSizingDashboardProvider: OpenAIDashboardProviding {
    func loadCachedDashboard() throws -> OpenAIDashboardCache? {
        nil
    }

    func loadAccountInfo() -> CodexAccountInfo {
        CodexAccountInfo(email: "person@example.com", plan: "Plus")
    }

    func refresh(
        settings _: OpenAIDashboardSettings,
        force _: Bool,
        logger _: ((String) -> Void)?) async throws -> OpenAIDashboardRefreshResult
    {
        throw OpenAIDashboardFetcher.FetchError.loginRequired
    }
}

@MainActor
private final class TokenMenuSizingLaunchAtLoginManager: LaunchAtLoginManaging {
    func isEnabled() -> Bool {
        false
    }

    func setEnabled(_: Bool) throws {}
}
