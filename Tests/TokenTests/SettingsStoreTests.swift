import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class SettingsStoreTests: XCTestCase {
    func test_updatesPersistToUserDefaults() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let manager = StubLaunchAtLoginManager()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: manager,
            preferredLanguages: { ["zh-Hans"] })

        settings.appLanguage = .ja
        settings.refreshFrequency = .fifteenSeconds
        settings.usageStatisticsRefreshFrequency = .sixtyMinutes
        settings.menuBarDisplayMode = .quota5h
        settings.menuBarQuotaStyle = .outline
        settings.showsMenuBarTokenSpeedMeter = true
        settings.remainingQuotaCardStyle = .fitness
        settings.menuPanelVersion = .unifiedCompact
        settings.menuPopupStyle = .systemPopover
        settings.menuVisualTheme = .cyberNeon
        settings.openAIWebAccessEnabled = false
        settings.backgroundBrowserAutoImportEnabled = false
        settings.codexCookieSource = .manual
        settings.codexCookieHeader = "foo=bar"

        XCTAssertEqual(defaults.string(forKey: "tokenAppLanguage"), AppLanguage.ja.rawValue)
        XCTAssertEqual(defaults.string(forKey: "tokenRefreshFrequency"), RefreshFrequency.fifteenSeconds.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenUsageStatisticsRefreshFrequency"),
            UsageStatisticsRefreshFrequency.sixtyMinutes.rawValue)
        XCTAssertEqual(defaults.string(forKey: "tokenMenuBarDisplayMode"), MenuBarDisplayMode.quota5h.rawValue)
        XCTAssertEqual(defaults.string(forKey: "tokenMenuBarQuotaStyle"), MenuBarQuotaStyle.outline.rawValue)
        XCTAssertEqual(defaults.bool(forKey: "tokenShowsMenuBarTokenSpeedMeter"), true)
        XCTAssertEqual(
            defaults.string(forKey: "tokenRemainingQuotaCardStyle"),
            RemainingQuotaCardStyle.fitness.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenMenuPanelVersion"),
            MenuPanelVersion.unifiedCompact.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenMenuPopupStyle"),
            MenuPopupStyle.systemPopover.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenMenuVisualTheme"),
            MenuVisualTheme.cyberNeon.rawValue)
        XCTAssertEqual(defaults.bool(forKey: "tokenOpenAIWebAccessEnabled"), false)
        XCTAssertEqual(defaults.bool(forKey: "tokenBackgroundBrowserAutoImportEnabled"), false)
        XCTAssertEqual(defaults.string(forKey: "tokenCodexCookieSource"), ProviderCookieSource.manual.rawValue)
        XCTAssertEqual(defaults.string(forKey: "tokenCodexCookieHeader"), "foo=bar")
    }

    func test_defaultsRefreshFrequencyToOneMinute() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(settings.refreshFrequency, .oneMinute)
        XCTAssertEqual(settings.usageStatisticsRefreshFrequency, .thirtyMinutes)
    }

    func test_legacyAutomaticRefreshFrequencyMigratesToOneMinute() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(RefreshFrequency.fifteenSeconds.rawValue, forKey: "tokenRefreshFrequency")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(settings.refreshFrequency, .oneMinute)
        XCTAssertEqual(defaults.string(forKey: "tokenRefreshFrequency"), RefreshFrequency.oneMinute.rawValue)
        XCTAssertEqual(defaults.bool(forKey: "tokenRefreshFrequencyMigratedToOneMinute"), true)
    }

    func test_manualRefreshFrequencyDoesNotMigrate() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(RefreshFrequency.manual.rawValue, forKey: "tokenRefreshFrequency")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(settings.refreshFrequency, .manual)
        XCTAssertEqual(defaults.string(forKey: "tokenRefreshFrequency"), RefreshFrequency.manual.rawValue)
        XCTAssertEqual(defaults.bool(forKey: "tokenRefreshFrequencyMigratedToOneMinute"), true)
    }

    func test_legacyMenuBarDisplayModeMigratesToTodayIO() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set("compact", forKey: "tokenMenuBarDisplayMode")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(settings.menuBarDisplayMode, .todayIO)
    }

    func test_menuBarAppearanceOptionMapsToTodayIOWithoutOverwritingQuotaStyle() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        settings.menuBarDisplayMode = .quota5h
        settings.menuBarQuotaStyle = .outline

        settings.menuBarAppearanceOption = .todayIO

        XCTAssertEqual(settings.menuBarDisplayMode, .todayIO)
        XCTAssertEqual(settings.menuBarQuotaStyle, .outline)
        XCTAssertEqual(settings.menuBarAppearanceOption, .todayIO)
    }

    func test_menuBarAppearanceOptionMapsQuotaStylesBackToPersistedState() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        let expectations: [(MenuBarAppearanceOption, MenuBarQuotaStyle)] = [
            (.classicCapsule, .capsule),
            (.splitBadge, .split),
            (.slimMeter, .meter),
            (.lightOutline, .outline),
            (.codexMinimal, .codexMinimal),
        ]

        for (option, quotaStyle) in expectations {
            settings.menuBarAppearanceOption = option

            XCTAssertEqual(settings.menuBarDisplayMode, .quota5h)
            XCTAssertEqual(settings.menuBarQuotaStyle, quotaStyle)
            XCTAssertEqual(settings.menuBarAppearanceOption, option)
        }

        settings.menuBarQuotaStyle = .outline
        settings.menuBarAppearanceOption = .dualCompact

        XCTAssertEqual(settings.menuBarDisplayMode, .quotaDualCompact)
        XCTAssertEqual(settings.menuBarQuotaStyle, .outline)
        XCTAssertEqual(settings.menuBarAppearanceOption, .dualCompact)

        settings.menuBarQuotaStyle = .meter
        settings.menuBarAppearanceOption = .dualKnockout

        XCTAssertEqual(settings.menuBarDisplayMode, .quotaDualKnockout)
        XCTAssertEqual(settings.menuBarQuotaStyle, .meter)
        XCTAssertEqual(settings.menuBarAppearanceOption, .dualKnockout)
    }

    func test_menuBarAppearanceOptionDerivesFromExistingSettingsState() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })

        let expectations: [(MenuBarDisplayMode, MenuBarQuotaStyle, MenuBarAppearanceOption)] = [
            (.todayIO, .capsule, .todayIO),
            (.quota5h, .capsule, .classicCapsule),
            (.quota5h, .split, .splitBadge),
            (.quota5h, .meter, .slimMeter),
            (.quota5h, .outline, .lightOutline),
            (.quota5h, .codexMinimal, .codexMinimal),
            (.quotaDualCompact, .capsule, .dualCompact),
            (.quotaDualKnockout, .capsule, .dualKnockout),
        ]

        for (mode, quotaStyle, option) in expectations {
            settings.menuBarDisplayMode = mode
            settings.menuBarQuotaStyle = quotaStyle

            XCTAssertEqual(settings.menuBarAppearanceOption, option)
        }
    }

    func test_launchAtLoginErrorIsStoredWhenRegistrationFails() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let manager = StubLaunchAtLoginManager()
        manager.error = StubLaunchAtLoginManager.StubError.registrationFailed
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: manager,
            preferredLanguages: { ["en-US"] })

        settings.launchAtLoginEnabled = true

        XCTAssertEqual(
            settings.launchAtLoginError,
            StubLaunchAtLoginManager.StubError.registrationFailed.localizedDescription)
    }

    func test_mainPanelHeightCachePersistsAcrossStoreRecreation() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let key = TokenMenuPanelHeightCacheKey(
            menuPanelVersion: MenuPanelVersion.current.rawValue,
            menuPopupStyle: MenuPopupStyle.liquidGlass.rawValue,
            sections: [.remainingQuota, .messageActivity, .footer],
            usageOverviewRowCount: 4,
            showsSparkQuotaCard: true)
        let firstStore = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        firstStore.persistMainPanelHeight(842, for: key)

        let secondStore = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(secondStore.storedMainPanelHeight(for: key), 842, accuracy: 0.1)
    }

    func test_mainPanelHeightCacheUsesStructureKey() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let currentKey = TokenMenuPanelHeightCacheKey(
            menuPanelVersion: MenuPanelVersion.current.rawValue,
            menuPopupStyle: MenuPopupStyle.liquidGlass.rawValue,
            sections: [.remainingQuota, .messageActivity, .footer],
            usageOverviewRowCount: 4,
            showsSparkQuotaCard: false)
        let changedKey = TokenMenuPanelHeightCacheKey(
            menuPanelVersion: MenuPanelVersion.unifiedCompact.rawValue,
            menuPopupStyle: MenuPopupStyle.systemPopover.rawValue,
            sections: [.remainingQuota, .messageActivity, .footer],
            usageOverviewRowCount: 4,
            showsSparkQuotaCard: false)
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        settings.persistMainPanelHeight(900, for: currentKey)

        XCTAssertEqual(settings.storedMainPanelHeight(for: currentKey), 900, accuracy: 0.1)
        XCTAssertNil(settings.storedMainPanelHeight(for: changedKey))
    }

    func test_systemLanguageResolvesFromPreferredLanguages() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["ja-JP"] })

        XCTAssertEqual(settings.appLanguage, .system)
        XCTAssertEqual(settings.resolvedLanguage, .ja)
    }

    func test_dashboardCardVisibilityDefaultsMatchFirstInstallLayoutAndPersist() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })

        XCTAssertEqual(settings.remainingQuotaCardStyle, .glass)
        XCTAssertEqual(settings.recentFortyEightHourChartStyle, .bars)
        XCTAssertEqual(settings.menuBarQuotaStyle, .capsule)
        XCTAssertFalse(settings.showsMenuBarTokenSpeedMeter)
        XCTAssertEqual(settings.menuPanelVersion, .current)
        XCTAssertEqual(settings.menuPopupStyle, .liquidGlass)
        XCTAssertEqual(settings.menuVisualTheme, .liquidGlassClassic)
        XCTAssertFalse(settings.openAIWebAccessEnabled)
        XCTAssertFalse(settings.backgroundBrowserAutoImportEnabled)
        XCTAssertEqual(settings.codexCookieSource, .manual)
        XCTAssertTrue(settings.showRemainingQuotaCard)
        XCTAssertTrue(settings.showSparkQuotaCard)
        XCTAssertFalse(settings.showCodeReviewCard)
        XCTAssertFalse(settings.showCreditsCard)
        XCTAssertFalse(settings.showUsageBreakdownCard)
        XCTAssertFalse(settings.showCreditsHistoryCard)
        XCTAssertTrue(settings.showThirtyDayChartCard)
        XCTAssertTrue(settings.showRecentTwentyFourHourChartCard)
        XCTAssertTrue(settings.showMessageActivityCard)
        XCTAssertTrue(settings.showUsageOverviewCard)
        XCTAssertFalse(settings.showUsageOverviewNumericCard)
        XCTAssertTrue(settings.showTodayUsageCard)
        XCTAssertTrue(settings.showSevenDayUsageCard)
        XCTAssertTrue(settings.showThirtyDayUsageCard)
        XCTAssertTrue(settings.showAllTimeUsageCard)
        XCTAssertEqual(settings.dashboardModuleOrder, DashboardModule.defaultOrder)

        settings.showRemainingQuotaCard = false
        settings.showSparkQuotaCard = false
        settings.menuBarQuotaStyle = .meter
        settings.remainingQuotaCardStyle = .fitness
        settings.recentFortyEightHourChartStyle = .wave
        settings.menuPanelVersion = .unifiedCompact
        settings.menuPopupStyle = .systemPopover
        settings.menuVisualTheme = .frenchCafe
        settings.showCodeReviewCard = false
        settings.showCreditsCard = false
        settings.showUsageBreakdownCard = false
        settings.showCreditsHistoryCard = false
        settings.showThirtyDayChartCard = false
        settings.showRecentTwentyFourHourChartCard = false
        settings.showMessageActivityCard = false
        settings.showUsageOverviewCard = false
        settings.showUsageOverviewNumericCard = true
        settings.showTodayUsageCard = false
        settings.showSevenDayUsageCard = false
        settings.showThirtyDayUsageCard = false
        settings.showAllTimeUsageCard = false
        settings.setDashboardModuleOrder([
            .creditsHistory,
            .usageBreakdown,
            .credits,
            .codeReview,
            .usageOverview,
            .lastThirtyDays,
            .recentFortyEightHours,
            .remainingQuota,
        ])

        XCTAssertEqual(defaults.object(forKey: "tokenShowRemainingQuotaCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowSparkQuotaCard") as? Bool, false)
        XCTAssertEqual(defaults.string(forKey: "tokenMenuBarQuotaStyle"), MenuBarQuotaStyle.meter.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenRemainingQuotaCardStyle"),
            RemainingQuotaCardStyle.fitness.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenRecentFortyEightHourChartStyle"),
            RecentFortyEightHourChartStyle.wave.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenMenuPanelVersion"),
            MenuPanelVersion.unifiedCompact.rawValue)
        XCTAssertEqual(
            defaults.string(forKey: "tokenMenuVisualTheme"),
            MenuVisualTheme.frenchCafe.rawValue)
        XCTAssertEqual(defaults.object(forKey: "tokenShowCodeReviewCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowCreditsCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowUsageBreakdownCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowCreditsHistoryCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowThirtyDayChartCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowRecentTwentyFourHourChartCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowMessageActivityCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowUsageOverviewCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowUsageOverviewNumericCard") as? Bool, true)
        XCTAssertEqual(defaults.object(forKey: "tokenShowTodayUsageCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowSevenDayUsageCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowThirtyDayUsageCard") as? Bool, false)
        XCTAssertEqual(defaults.object(forKey: "tokenShowAllTimeUsageCard") as? Bool, false)
        XCTAssertEqual(
            defaults.stringArray(forKey: "tokenDashboardModuleOrder"),
            [
                "creditsHistory",
                "usageBreakdown",
                "credits",
                "codeReview",
                "usageOverview",
                "lastThirtyDays",
                "messageActivity",
                "usageOverviewNumeric",
                "recentFortyEightHours",
                "remainingQuota",
            ])

        let reloaded = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })

        XCTAssertFalse(reloaded.showRemainingQuotaCard)
        XCTAssertFalse(reloaded.showSparkQuotaCard)
        XCTAssertEqual(reloaded.menuBarQuotaStyle, .meter)
        XCTAssertEqual(reloaded.remainingQuotaCardStyle, .fitness)
        XCTAssertEqual(reloaded.recentFortyEightHourChartStyle, .wave)
        XCTAssertEqual(reloaded.menuPanelVersion, .unifiedCompact)
        XCTAssertEqual(reloaded.menuPopupStyle, .systemPopover)
        XCTAssertEqual(reloaded.menuVisualTheme, .frenchCafe)
        XCTAssertFalse(reloaded.showCodeReviewCard)
        XCTAssertFalse(reloaded.showCreditsCard)
        XCTAssertFalse(reloaded.showUsageBreakdownCard)
        XCTAssertFalse(reloaded.showCreditsHistoryCard)
        XCTAssertFalse(reloaded.showThirtyDayChartCard)
        XCTAssertFalse(reloaded.showRecentTwentyFourHourChartCard)
        XCTAssertFalse(reloaded.showMessageActivityCard)
        XCTAssertFalse(reloaded.showUsageOverviewCard)
        XCTAssertTrue(reloaded.showUsageOverviewNumericCard)
        XCTAssertFalse(reloaded.showTodayUsageCard)
        XCTAssertFalse(reloaded.showSevenDayUsageCard)
        XCTAssertFalse(reloaded.showThirtyDayUsageCard)
        XCTAssertFalse(reloaded.showAllTimeUsageCard)
        XCTAssertEqual(
            reloaded.dashboardModuleOrder,
            [
                .creditsHistory,
                .usageBreakdown,
                .credits,
                .codeReview,
                .usageOverview,
                .lastThirtyDays,
                .messageActivity,
                .usageOverviewNumeric,
                .recentFortyEightHours,
                .remainingQuota,
            ])
    }

    func test_unknownMenuVisualThemeFallsBackToDefault() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set("random-theme", forKey: "tokenMenuVisualTheme")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(settings.menuVisualTheme, .liquidGlassClassic)
    }

    func test_savedDashboardCardVisibilityOverridesNewFirstInstallDefaults() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(true, forKey: "tokenShowCodeReviewCard")
        defaults.set(true, forKey: "tokenShowCreditsCard")
        defaults.set(true, forKey: "tokenShowUsageBreakdownCard")
        defaults.set(true, forKey: "tokenShowCreditsHistoryCard")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertTrue(settings.showCodeReviewCard)
        XCTAssertTrue(settings.showCreditsCard)
        XCTAssertTrue(settings.showUsageBreakdownCard)
        XCTAssertTrue(settings.showCreditsHistoryCard)
    }

    func test_dashboardModuleOrderNormalizesUnknownValuesDuplicatesAndMissingModules() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(
            [
                "credits",
                "unknown",
                "credits",
                "remainingQuota",
                "codeReview",
            ],
            forKey: "tokenDashboardModuleOrder")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(
            settings.dashboardModuleOrder,
            [
                .credits,
                .remainingQuota,
                .codeReview,
                .recentFortyEightHours,
                .messageActivity,
                .lastThirtyDays,
                .usageOverview,
                .usageOverviewNumeric,
                .usageBreakdown,
                .creditsHistory,
            ])
    }

    func test_recentFortyEightHourChartStyleFallsBackToBarsForUnknownValue() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set("unknown", forKey: "tokenRecentFortyEightHourChartStyle")

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        XCTAssertEqual(settings.recentFortyEightHourChartStyle, .bars)
    }
}

@MainActor
private final class StubLaunchAtLoginManager: LaunchAtLoginManaging {
    enum StubError: LocalizedError {
        case registrationFailed

        var errorDescription: String? {
            switch self {
            case .registrationFailed:
                "Unable to update launch at login."
            }
        }
    }

    var enabled = false
    var error: Error?

    func isEnabled() -> Bool {
        self.enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if let error = self.error {
            throw error
        }
        self.enabled = enabled
    }
}
