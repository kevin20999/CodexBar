import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class TokenPreferencesViewTests: XCTestCase {
    override func tearDown() {
        TokenMenuSpeedMeterFeature.supportsVisualPresentationOverride = nil
        super.tearDown()
    }

    func test_preferencesViewBuildsWithDefaultPreviewConfiguration() throws {
        let context = try self.makeContext()

        _ = PreferencesView(settings: context.settings, store: context.store).body
    }

    func test_preferencesViewBuildsWhenAllPreviewCardsAreVisible() throws {
        let context = try self.makeContext()
        context.settings.showCodeReviewCard = true
        context.settings.showCreditsCard = true
        context.settings.showUsageBreakdownCard = true
        context.settings.showCreditsHistoryCard = true
        context.settings.showThirtyDayChartCard = true
        context.settings.showRecentTwentyFourHourChartCard = true
        context.settings.showTodayUsageCard = true
        context.settings.showSevenDayUsageCard = true
        context.settings.showThirtyDayUsageCard = true
        context.settings.showAllTimeUsageCard = true
        context.store.openAIAccountPlanFallback = "Pro"

        _ = PreferencesView(settings: context.settings, store: context.store).body
    }

    func test_preferencesViewBuildsWhenOpenAIWebControlsAreVisible() throws {
        let context = try self.makeContext()
        context.settings.openAIWebAccessEnabled = true
        context.settings.codexCookieSource = .manual

        _ = PreferencesView(settings: context.settings, store: context.store).body
    }

    func test_preferencesViewBuildsWhenTokenSpeedMeterPreviewIsVisible() throws {
        TokenMenuSpeedMeterFeature.supportsVisualPresentationOverride = true
        let context = try self.makeContext()
        context.settings.showsMenuBarTokenSpeedMeter = true
        context.store.menuBarTokenSpeedMetrics = MenuBarTokenSpeedMetrics(tokensPerSecond: 48)

        _ = PreferencesView(settings: context.settings, store: context.store).body
    }

    func test_preferencesViewBuildsWhenSystemPopoverPreviewIsSelected() throws {
        let context = try self.makeContext()
        context.settings.menuPopupStyle = .systemPopover

        _ = PreferencesView(settings: context.settings, store: context.store).body
    }

    func test_previewMeasurementKeyChangesWhenPreviewCardsChange() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.showMessageActivityCard = false

        XCTAssertNotEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyIgnoresRecentFortyEightHourChartStyleChanges() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.recentFortyEightHourChartStyle = .wave

        XCTAssertEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyChangesWhenDashboardInputsChange() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.store.codexQuotaSnapshot = CodexQuotaSnapshot(
            primary: RateWindow(
                usedPercent: 44,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            secondary: nil,
            updatedAt: Date(),
            accountEmail: "person@example.com",
            accountPlan: "Pro")
        let codexQuotaKey = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)
        XCTAssertNotEqual(baseline, codexQuotaKey)

        context.store.openAIDashboard = self.makeDashboardSnapshot(accountPlan: "Plus")
        let snapshotKey = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)
        XCTAssertNotEqual(codexQuotaKey, snapshotKey)

        context.store.openAIAccountPlanFallback = "Pro"
        let fallbackPlanKey = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)
        XCTAssertNotEqual(snapshotKey, fallbackPlanKey)

        context.store.lastOpenAIDashboardError = "Login required"
        let dashboardErrorKey = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)
        XCTAssertNotEqual(fallbackPlanKey, dashboardErrorKey)

        context.store.lastError = "History refresh failed"
        XCTAssertNotEqual(
            dashboardErrorKey,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyChangesWhenSparkQuotaToggleChanges() throws {
        let context = try self.makeContext()
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
                usedPercent: 28,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondaryLimit: RateWindow(
                usedPercent: 19,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil),
            creditsRemaining: nil,
            accountPlan: "Plus",
            updatedAt: Date())
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.showSparkQuotaCard = false

        XCTAssertNotEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyChangesWhenUsageOverviewNumericToggleChanges() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.showUsageOverviewNumericCard = true

        XCTAssertNotEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyIgnoresLanguageAndRefreshFrequencyChanges() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.appLanguage = .zhHans
        context.settings.refreshFrequency = .manual
        context.settings.usageStatisticsRefreshFrequency = .manual

        XCTAssertEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyChangesWhenMenuPopupStyleChanges() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.menuPopupStyle = .systemPopover

        XCTAssertNotEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyChangesWhenMenuVisualThemeChanges() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.menuVisualTheme = .sakura

        XCTAssertNotEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    func test_previewMeasurementKeyChangesWhenDashboardModuleOrderChanges() throws {
        let context = try self.makeContext()
        let baseline = TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store)

        context.settings.setDashboardModuleOrder([
            .creditsHistory,
            .remainingQuota,
            .recentFortyEightHours,
            .messageActivity,
            .lastThirtyDays,
            .usageOverview,
            .usageOverviewNumeric,
            .codeReview,
            .credits,
            .usageBreakdown,
        ])

        XCTAssertNotEqual(
            baseline,
            TokenSettingsPreviewMeasurementKey(settings: context.settings, store: context.store))
    }

    private func makeContext() throws -> TokenPreferencesViewTestContext {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: TokenPreferencesViewLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let sandbox = try TokenPreferencesViewSandbox()
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: TokenPreferencesViewDashboardProvider(),
            startupRefresh: false)

        return TokenPreferencesViewTestContext(settings: settings, store: store)
    }

    private func makeDashboardSnapshot(accountPlan: String) -> OpenAIDashboardSnapshot {
        OpenAIDashboardSnapshot(
            signedInEmail: "person@example.com",
            codeReviewRemainingPercent: 72,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: RateWindow(
                usedPercent: 28,
                windowMinutes: 300,
                resetsAt: nil,
                resetDescription: "Resets soon"),
            creditsRemaining: 19.5,
            accountPlan: accountPlan,
            updatedAt: Date(timeIntervalSince1970: 1_710_000_000))
    }
}

private struct TokenPreferencesViewTestContext {
    let settings: SettingsStore
    let store: UsageStore
}

private struct TokenPreferencesViewSandbox {
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
private final class TokenPreferencesViewDashboardProvider: OpenAIDashboardProviding {
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
private final class TokenPreferencesViewLaunchAtLoginManager: LaunchAtLoginManaging {
    func isEnabled() -> Bool {
        false
    }

    func setEnabled(_: Bool) throws {}
}
