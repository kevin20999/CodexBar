import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

@MainActor
final class UsageStoreTests: XCTestCase {
    override func tearDown() {
        TokenMenuSpeedMeterFeature.supportsVisualPresentationOverride = nil
        super.tearDown()
    }

    func test_menuBarTextUsesConfiguredDisplayMode() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let historyStore = TokenHistoryStore(fileURL: sandbox.fileURL)
        let todayKey = DailyTokenStats.dayKey(for: Date(), calendar: Calendar.current)
        let document = TokenHistoryDocument(
            sessions: [:],
            days: [DailyTokenStats(
                date: todayKey,
                inputTokens: 12345,
                outputTokens: 987,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 13332)],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: historyStore)
        let dashboardProvider = FakeOpenAIDashboardProvider()
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        settings.menuBarDisplayMode = .todayIO
        XCTAssertEqual(store.menuBarText, "In 12.3k Out 987")
        XCTAssertEqual(
            store.menuBarDisplayMetrics,
            MenuBarDisplayMetrics(
                inputText: "12.3k",
                outputText: "987",
                quotaPercentText: "--",
                quotaFraction: nil,
                quotaIsStale: false,
                primaryQuotaShortLabel: "H",
                primaryQuotaSummaryLabel: "5 hours"))

        store.codexQuotaSnapshot = Self.makeCodexQuotaSnapshot(updatedAt: Date())
        settings.menuBarDisplayMode = .quota5h
        XCTAssertEqual(store.menuBarText, "5h 56%")
        XCTAssertEqual(store.menuBarDisplayMetrics.quotaPercentText, "56%")
        XCTAssertEqual(try XCTUnwrap(store.menuBarDisplayMetrics.quotaFraction), 0.56, accuracy: 0.001)

        settings.menuBarDisplayMode = .quotaDualCompact
        XCTAssertEqual(store.menuBarText, "5 hours 56%, 1 week 88%")
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.shortLabel, "H")
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.compactPercentText, "56")
        XCTAssertEqual(store.menuBarDisplayMetrics.secondaryQuota?.shortLabel, "W")
        XCTAssertEqual(store.menuBarDisplayMetrics.secondaryQuota?.compactPercentText, "88")

        settings.menuBarDisplayMode = .quotaDualKnockout
        XCTAssertEqual(store.menuBarText, "5 hours 56%, 1 week 88%")
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.shortLabel, "H")
        XCTAssertEqual(store.menuBarDisplayMetrics.secondaryQuota?.shortLabel, "W")
    }

    func test_tokenDailyBoardStoreMatchesUsageStoreForIndependentCaches() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let usageSandbox = try UsageStoreSandbox()
        let dailySandbox = try UsageStoreSandbox()
        let refreshDate = Date(timeIntervalSince1970: 1_744_096_000)
        let todayKey = DailyTokenStats.dayKey(for: Date(), calendar: .current)
        let sixDaysAgoKey = DailyTokenStats.dayKey(for: Calendar.current.date(
            byAdding: .day,
            value: -6,
            to: Date()) ?? Date(), calendar: .current)
        let thirtyDaysAgoKey = DailyTokenStats.dayKey(for: Calendar.current.date(
            byAdding: .day,
            value: -29,
            to: Date()) ?? Date(), calendar: .current)
        let result = TokenRefreshResult(
            sessions: [
                "regular-session": SessionUsageSnapshot(
                    sessionID: "regular-session",
                    sessionOriginKind: .regular,
                    sourceFile: "/tmp/regular.jsonl",
                    sourceFileSize: nil,
                    sourceFileModificationTime: refreshDate,
                    lastEventAt: refreshDate,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: thirtyDaysAgoKey,
                            inputTokens: 100,
                            outputTokens: 10,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 110),
                        DailyTokenStats(
                            date: sixDaysAgoKey,
                            inputTokens: 200,
                            outputTokens: 20,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 220),
                        DailyTokenStats(
                            date: todayKey,
                            inputTokens: 300,
                            outputTokens: 30,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 330),
                    ]),
                "spawned-session": SessionUsageSnapshot(
                    sessionID: "spawned-session",
                    sessionOriginKind: .subagentThreadSpawn,
                    sourceFile: "/tmp/spawned.jsonl",
                    sourceFileSize: nil,
                    sourceFileModificationTime: refreshDate,
                    lastEventAt: refreshDate,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: sixDaysAgoKey,
                            inputTokens: 400,
                            outputTokens: 40,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 440),
                        DailyTokenStats(
                            date: todayKey,
                            inputTokens: 500,
                            outputTokens: 50,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 550),
                    ]),
            ],
            days: [
                DailyTokenStats(
                    date: thirtyDaysAgoKey,
                    inputTokens: 100,
                    outputTokens: 10,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 110),
                DailyTokenStats(
                    date: sixDaysAgoKey,
                    inputTokens: 600,
                    outputTokens: 60,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 660),
                DailyTokenStats(
                    date: todayKey,
                    inputTokens: 800,
                    outputTokens: 80,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 880),
            ],
            hours: [],
            fiveMinuteBuckets: [],
            outboundMessageDays: [],
            refreshedAt: refreshDate,
            scannedFileCount: 2,
            reusedSessionCount: 0,
            errors: [])

        _ = try TokenHistoryStore(fileURL: usageSandbox.fileURL).merge(refreshResult: result)
        _ = try TokenHistoryStore(fileURL: dailySandbox.fileURL).merge(refreshResult: result)

        let usageStore = UsageStore(
            settings: SettingsStore(
                defaults: defaults,
                launchAtLoginManager: FakeLaunchAtLoginManager(),
                preferredLanguages: { ["zh-Hans"] }),
            provider: CodexSessionTokenProvider(
                sessionRootURL: usageSandbox.root.appendingPathComponent("sessions", isDirectory: true),
                historyStore: TokenHistoryStore(fileURL: usageSandbox.fileURL)),
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)
        let dailyStore = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: dailySandbox.fileURL),
            autoStartMonitoring: false)

        XCTAssertEqual(dailyStore.days, usageStore.days)
        XCTAssertEqual(dailyStore.regularDays, usageStore.regularDays)
        XCTAssertEqual(dailyStore.days.first(where: { $0.date == todayKey })?.totalTokens, usageStore.today.totalTokens)
        XCTAssertEqual(
            dailyStore.regularDays.first(where: { $0.date == todayKey })?.totalTokens,
            usageStore.regularToday.totalTokens)
        XCTAssertEqual(
            dailyStore.days.filter { Set([todayKey, sixDaysAgoKey]).contains($0.date) }
                .reduce(0) { $0 + $1.totalTokens },
            usageStore.sevenDayTotal.totalTokens)
        XCTAssertEqual(
            dailyStore.regularDays.filter { Set([todayKey, sixDaysAgoKey]).contains($0.date) }
                .reduce(0) { $0 + $1.totalTokens },
            usageStore.regularSevenDayTotal.totalTokens)
        XCTAssertEqual(
            dailyStore.days.filter { Set([todayKey, sixDaysAgoKey, thirtyDaysAgoKey]).contains($0.date) }
                .reduce(0) { $0 + $1.totalTokens },
            usageStore.thirtyDayTotal.totalTokens)
        XCTAssertEqual(
            dailyStore.regularDays.filter { Set([todayKey, sixDaysAgoKey, thirtyDaysAgoKey]).contains($0.date) }
                .reduce(0) { $0 + $1.totalTokens },
            usageStore.regularThirtyDayTotal.totalTokens)
        XCTAssertEqual(dailyStore.days.reduce(0) { $0 + $1.totalTokens }, usageStore.cumulativeTotal.totalTokens)
        XCTAssertEqual(
            dailyStore.regularDays.reduce(0) { $0 + $1.totalTokens },
            usageStore.regularCumulativeTotal.totalTokens)
    }

    func test_dualCompactModeFallsBackToPrimaryOnlyWhenSecondaryMissing() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        store.codexQuotaSnapshot = Self.makeCodexQuotaSnapshot(updatedAt: Date(), secondaryLimit: nil)
        settings.menuBarDisplayMode = .quotaDualKnockout

        XCTAssertEqual(store.menuBarText, "5 小时 56%")
        XCTAssertNil(store.menuBarDisplayMetrics.secondaryQuota)
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.shortLabel, "H")
    }

    func test_menuBarTokenSpeedMetricsFormatsIconsAndText() {
        XCTAssertEqual(MenuBarTokenSpeedMetrics(tokensPerSecond: 0).displayText, "☕️ 0 token/s")
        XCTAssertEqual(MenuBarTokenSpeedMetrics(tokensPerSecond: 4).icon, "🚀")
        XCTAssertEqual(MenuBarTokenSpeedMetrics(tokensPerSecond: 160).icon, "🚀")
        XCTAssertEqual(MenuBarTokenSpeedMetrics.historyIcon(for: 0), "🐢")
        XCTAssertEqual(MenuBarTokenSpeedMetrics.historyIcon(for: 79), "🚆")
        XCTAssertEqual(MenuBarTokenSpeedMetrics.historyIcon(for: 160), "🚀")
    }

    func test_tokenSpeedMeterStartsAndStopsWithSetting() async throws {
        TokenMenuSpeedMeterFeature.supportsVisualPresentationOverride = true
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let historyFileURL = sandbox.root.appendingPathComponent("token_speed_history.json", isDirectory: false)
        let monitor = FakeTokenRateMonitor(samples: [
            TokenSpeedSample(timestamp: Date(timeIntervalSince1970: 1_800_000_000), tokens: 48),
            TokenSpeedSample(timestamp: Date(timeIntervalSince1970: 1_800_000_001), tokens: 0),
        ])
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            tokenRateMonitor: monitor,
            tokenSpeedHistoryStore: TokenSpeedHistoryStore(fileURL: historyFileURL),
            startupRefresh: false)

        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(store.menuBarTokenSpeedMetrics, .zero)
        await XCTAssertEqual(monitor.resetCallCount, 1)

        settings.showsMenuBarTokenSpeedMeter = true
        try await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.menuBarTokenSpeedMetrics, MenuBarTokenSpeedMetrics(tokensPerSecond: 48))
        XCTAssertGreaterThan(store.menuBarTokenSpeedMetrics.launchStrength, 0)
        XCTAssertEqual(store.menuBarTokenSpeedMetrics.launchDate, Date(timeIntervalSince1970: 1_800_000_000))
        XCTAssertEqual(store.recentTokenSpeedSamples.count, 600)
        XCTAssertEqual(store.tokenSpeedHistoryEntries.first?.tokens, 48)
        await XCTAssertEqual(monitor.resetCallCount, 2)

        settings.showsMenuBarTokenSpeedMeter = false
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(store.menuBarTokenSpeedMetrics, .zero)
        await XCTAssertEqual(monitor.resetCallCount, 3)
    }

    func test_tokenSpeedHistoryLoadsAndKeepsRecentTimelinePadded() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let historyStore = TokenSpeedHistoryStore(
            fileURL: sandbox.root.appendingPathComponent("token_speed_history.json", isDirectory: false))

        _ = try historyStore.upsert(sample: TokenSpeedSample(
            timestamp: Date().addingTimeInterval(-10),
            tokens: 32))

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            tokenSpeedHistoryStore: historyStore,
            startupRefresh: false)

        XCTAssertEqual(store.recentTokenSpeedSamples.count, 600)
        XCTAssertEqual(store.tokenSpeedHistoryEntries.count, 1)
        XCTAssertEqual(store.tokenSpeedHistoryEntries.first?.tokens, 32)
        XCTAssertTrue(store.recentTokenSpeedSamples.contains(where: { $0.tokens == 32 }))
    }

    func test_dualCompactModeUsesFallbackPrimaryWindowLabelWhenExact5hIsMissing() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["ja-JP"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        store.codexQuotaSnapshot = Self.makeCodexQuotaSnapshot(
            updatedAt: Date(),
            primaryLimit: RateWindow(usedPercent: 35, windowMinutes: 12 * 60, resetsAt: nil, resetDescription: nil),
            secondaryLimit: nil)
        settings.menuBarDisplayMode = .quotaDualCompact

        XCTAssertEqual(store.menuBarText, "12時間 65%")
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.shortLabel, "12H")
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.summaryLabel, "12時間")
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.compactPercentText, "65")
        XCTAssertNil(store.menuBarDisplayMetrics.secondaryQuota)
    }

    func test_dualCompactModeFormatsWeeklyMultiplesWithCompactLabels() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        store.codexQuotaSnapshot = Self.makeCodexQuotaSnapshot(
            updatedAt: Date(),
            secondaryLimit: RateWindow(
                usedPercent: 12,
                windowMinutes: 14 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil))
        settings.menuBarDisplayMode = .quotaDualCompact

        XCTAssertEqual(store.menuBarDisplayMetrics.secondaryQuota?.shortLabel, "2W")
        XCTAssertEqual(store.menuBarText, "5 hours 56%, 2 weeks 88%")
    }

    func test_menuBarQuotaUsesCodexQuotaWhenOpenAIWebStateIsStale() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        store.codexQuotaSnapshot = Self.makeCodexQuotaSnapshot(updatedAt: Date())
        store.openAIDashboardIsStale = true
        settings.menuBarDisplayMode = .quotaDualCompact

        XCTAssertEqual(store.menuBarText, "5 hours 56%, 1 week 88%")
        XCTAssertFalse(store.menuBarDisplayMetrics.quotaIsStale)
        XCTAssertEqual(store.menuBarDisplayMetrics.primaryQuota.summaryLabel, "5 hours")
        XCTAssertEqual(store.menuBarDisplayMetrics.secondaryQuota?.summaryLabel, "1 week")
    }

    func test_trailingSeriesAlwaysContainsRequestedWindow() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        XCTAssertEqual(store.trailingSevenDays.count, 7)
        XCTAssertEqual(store.trailingThirtyDays.count, 30)
    }

    func test_outboundMessageSeriesPadsMissingDaysAndComputesTotals() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let todayKey = DailyTokenStats.dayKey(for: today, calendar: calendar)
        let twoDaysAgoKey = DailyTokenStats.dayKey(for: twoDaysAgo, calendar: calendar)
        let document = TokenHistoryDocument(
            sessions: [:],
            days: [],
            hours: [],
            outboundMessageDays: [
                DailyOutboundMessageStats(
                    date: twoDaysAgoKey,
                    sentCharacters: 80,
                    sentMessages: 2),
                DailyOutboundMessageStats(
                    date: todayKey,
                    sentCharacters: 120,
                    sentMessages: 3),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: sandbox.fileURL, options: .atomic)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        XCTAssertEqual(store.trailingThirtyOutboundMessageDays.count, 30)
        XCTAssertEqual(store.trailingThirtyOutboundMessageDays.last?.sentCharacters, 120)
        XCTAssertEqual(store.trailingThirtyOutboundMessageDays[27].sentCharacters, 80)
        XCTAssertEqual(store.todayOutboundMessages.sentMessages, 3)
        XCTAssertEqual(store.trailingSevenOutboundMessageDays.count, 7)
        XCTAssertEqual(store.sevenDayOutboundMessageTotal.sentCharacters, 200)
        XCTAssertEqual(store.sevenDayOutboundMessageTotal.sentMessages, 5)
        XCTAssertEqual(store.thirtyDayOutboundMessageTotal.sentCharacters, 200)
        XCTAssertEqual(store.thirtyDayOutboundMessageTotal.sentMessages, 5)
        XCTAssertEqual(store.cumulativeOutboundMessageTotal.sentCharacters, 200)
        XCTAssertEqual(store.cumulativeOutboundMessageTotal.sentMessages, 5)
    }

    func test_trailingTwentyFourHoursContainsRequestedWindowAndPadsMissingHours() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let currentHourStart = Self.currentHourStart()
        let twoHoursAgo = try XCTUnwrap(
            Calendar.current.date(byAdding: .hour, value: -2, to: currentHourStart))
        let document = TokenHistoryDocument(
            sessions: [:],
            days: [],
            hours: [
                HourlyTokenStats(
                    hourStart: twoHoursAgo,
                    inputTokens: 30,
                    outputTokens: 10,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 40),
                HourlyTokenStats(
                    hourStart: currentHourStart,
                    inputTokens: 7,
                    outputTokens: 2,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 9),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        let trailingHours = store.trailingTwentyFourHours
        XCTAssertEqual(store.hours.count, 2)
        XCTAssertEqual(trailingHours.count, 24)
        XCTAssertEqual(trailingHours.last?.hourStart, currentHourStart)
        XCTAssertEqual(trailingHours.last?.totalTokens, 9)
        XCTAssertEqual(trailingHours[21].totalTokens, 40)
        XCTAssertEqual(trailingHours[22].totalTokens, 0)
    }

    func test_loadPersistedHistoryIncludesFiveMinuteBuckets() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let currentHourStart = Self.currentHourStart()
        let currentBucketStart = try XCTUnwrap(
            Calendar.current.date(byAdding: .minute, value: 10, to: currentHourStart))
        let nextBucketStart = try XCTUnwrap(
            Calendar.current.date(byAdding: .minute, value: 15, to: currentHourStart))
        let document = TokenHistoryDocument(
            sessions: [:],
            days: [],
            hours: [],
            fiveMinuteBuckets: [
                FiveMinuteTokenStats(
                    bucketStart: currentBucketStart,
                    inputTokens: 10,
                    outputTokens: 4,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 14),
                FiveMinuteTokenStats(
                    bucketStart: nextBucketStart,
                    inputTokens: 2,
                    outputTokens: 1,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 3),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        XCTAssertEqual(store.fiveMinuteBuckets.count, 2)
        XCTAssertEqual(store.fiveMinuteBuckets.first?.bucketStart, currentBucketStart)
        XCTAssertEqual(store.fiveMinuteBuckets.last?.bucketStart, nextBucketStart)
        XCTAssertEqual(store.fiveMinuteBuckets.first?.totalTokens, 14)
        XCTAssertEqual(store.fiveMinuteBuckets.last?.totalTokens, 3)
    }

    func test_trailingFortyEightHoursContainsRequestedWindowAndPadsMissingHours() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let currentHourStart = Self.currentHourStart()
        let twoHoursAgo = try XCTUnwrap(
            Calendar.current.date(byAdding: .hour, value: -2, to: currentHourStart))
        let document = TokenHistoryDocument(
            sessions: [:],
            days: [],
            hours: [
                HourlyTokenStats(
                    hourStart: twoHoursAgo,
                    inputTokens: 30,
                    outputTokens: 10,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 40),
                HourlyTokenStats(
                    hourStart: currentHourStart,
                    inputTokens: 7,
                    outputTokens: 2,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 9),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        let trailingHours = store.trailingFortyEightHours
        XCTAssertEqual(store.hours.count, 2)
        XCTAssertEqual(trailingHours.count, 48)
        XCTAssertEqual(trailingHours.last?.hourStart, currentHourStart)
        XCTAssertEqual(trailingHours.last?.totalTokens, 9)
        XCTAssertEqual(trailingHours[45].totalTokens, 40)
        XCTAssertEqual(trailingHours[46].totalTokens, 0)
    }

    func test_persistedHistoryDerivesRegularOnlyUsageSummariesFromSessionSnapshots() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentHourStart = Self.currentHourStart()
        let previousHourStart = try XCTUnwrap(calendar.date(byAdding: .hour, value: -1, to: currentHourStart))
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let todayKey = DailyTokenStats.dayKey(for: today, calendar: calendar)
        let twoDaysAgoKey = DailyTokenStats.dayKey(for: twoDaysAgo, calendar: calendar)
        let regularToday = DailyTokenStats(
            date: todayKey,
            inputTokens: 5,
            outputTokens: 3,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 8)
        let regularTwoDaysAgo = DailyTokenStats(
            date: twoDaysAgoKey,
            inputTokens: 2,
            outputTokens: 2,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 4)
        let subagentToday = DailyTokenStats(
            date: todayKey,
            inputTokens: 10,
            outputTokens: 3,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 13)
        let regularCurrentHour = HourlyTokenStats(
            hourStart: currentHourStart,
            inputTokens: 5,
            outputTokens: 3,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 8)
        let regularPreviousHour = HourlyTokenStats(
            hourStart: previousHourStart,
            inputTokens: 2,
            outputTokens: 2,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 4)
        let subagentCurrentHour = HourlyTokenStats(
            hourStart: currentHourStart,
            inputTokens: 10,
            outputTokens: 3,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 13)
        let document = TokenHistoryDocument(
            sessions: [
                "regular": SessionUsageSnapshot(
                    sessionID: "regular",
                    sessionOriginKind: .regular,
                    sourceFile: "/tmp/regular.jsonl",
                    sourceFileSize: nil,
                    sourceFileModificationTime: nil,
                    lastEventAt: today,
                    dailyBuckets: [regularTwoDaysAgo, regularToday],
                    hourlyBuckets: [regularPreviousHour, regularCurrentHour]),
                "subagent": SessionUsageSnapshot(
                    sessionID: "subagent",
                    sessionOriginKind: .subagentThreadSpawn,
                    sourceFile: "/tmp/subagent.jsonl",
                    sourceFileSize: nil,
                    sourceFileModificationTime: nil,
                    lastEventAt: today,
                    dailyBuckets: [subagentToday],
                    hourlyBuckets: [subagentCurrentHour]),
            ],
            days: [
                DailyTokenStats(
                    date: twoDaysAgoKey,
                    inputTokens: 2,
                    outputTokens: 2,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 4),
                DailyTokenStats(
                    date: todayKey,
                    inputTokens: 15,
                    outputTokens: 6,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 21),
            ],
            hours: [
                regularPreviousHour,
                HourlyTokenStats(
                    hourStart: currentHourStart,
                    inputTokens: 15,
                    outputTokens: 6,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 21),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        XCTAssertEqual(store.today.totalTokens, 21)
        XCTAssertEqual(store.regularToday.totalTokens, 8)
        XCTAssertEqual(store.sevenDayTotal.totalTokens, 25)
        XCTAssertEqual(store.regularSevenDayTotal.totalTokens, 12)
        XCTAssertEqual(store.thirtyDayTotal.totalTokens, 25)
        XCTAssertEqual(store.regularThirtyDayTotal.totalTokens, 12)
        XCTAssertEqual(store.cumulativeTotal.totalTokens, 25)
        XCTAssertEqual(store.regularCumulativeTotal.totalTokens, 12)
        XCTAssertEqual(store.regularDays.map(\.totalTokens), [4, 8])
        XCTAssertEqual(store.trailingFortyEightHours.reduce(0) { $0 + $1.totalTokens }, 25)
        XCTAssertEqual(store.trailingFortyEightHours.last?.totalTokens, 21)
        XCTAssertEqual(store.regularTrailingFortyEightHours.reduce(0) { $0 + $1.totalTokens }, 12)
        XCTAssertEqual(store.regularTrailingFortyEightHours[46].totalTokens, 4)
        XCTAssertEqual(store.regularTrailingFortyEightHours.last?.totalTokens, 8)
    }

    func test_usageOverviewPresentationBuilderBindsPrimaryAndMainThreadMetrics() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let todayKey = DailyTokenStats.dayKey(for: today, calendar: calendar)
        let twoDaysAgoKey = DailyTokenStats.dayKey(for: twoDaysAgo, calendar: calendar)
        let regularToday = DailyTokenStats(
            date: todayKey,
            inputTokens: 5,
            outputTokens: 3,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 8)
        let regularTwoDaysAgo = DailyTokenStats(
            date: twoDaysAgoKey,
            inputTokens: 2,
            outputTokens: 2,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 4)
        let subagentToday = DailyTokenStats(
            date: todayKey,
            inputTokens: 10,
            outputTokens: 3,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 13)
        let document = TokenHistoryDocument(
            sessions: [
                "regular": SessionUsageSnapshot(
                    sessionID: "regular",
                    sessionOriginKind: .regular,
                    sourceFile: "/tmp/regular.jsonl",
                    sourceFileSize: nil,
                    sourceFileModificationTime: nil,
                    lastEventAt: today,
                    dailyBuckets: [regularTwoDaysAgo, regularToday]),
                "subagent": SessionUsageSnapshot(
                    sessionID: "subagent",
                    sessionOriginKind: .subagentThreadSpawn,
                    sourceFile: "/tmp/subagent.jsonl",
                    sourceFileSize: nil,
                    sourceFileModificationTime: nil,
                    lastEventAt: today,
                    dailyBuckets: [subagentToday]),
            ],
            days: [
                DailyTokenStats(
                    date: twoDaysAgoKey,
                    inputTokens: 2,
                    outputTokens: 2,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 4),
                DailyTokenStats(
                    date: todayKey,
                    inputTokens: 15,
                    outputTokens: 6,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 21),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        let rows = UsageOverviewPresentationBuilder.rows(store: store, settings: settings, strings: settings.strings)
        let items = UsageOverviewPresentationBuilder.numericItems(store: store, strings: settings.strings)

        XCTAssertEqual(rows.map(\.title), ["Today", "7 days", "30 days", "Local history"])
        XCTAssertEqual(rows.last?.stats.totalTokens, 25)
        XCTAssertEqual(rows.last?.secondaryStats?.totalTokens, 12)
        XCTAssertEqual(rows.first?.secondaryStats?.inputTokens, 5)

        XCTAssertEqual(items.map(\.title), ["Today", "7 days", "30 days", "Local history"])
        XCTAssertEqual(items.last?.value, 25)
        XCTAssertEqual(items.last?.primaryAmountText, "25")
        XCTAssertNil(items.last?.primaryUnitText)
        XCTAssertEqual(items.last?.secondaryLabelText, "Main thread")
        XCTAssertEqual(items.last?.secondaryAmountText, "12")
        XCTAssertNil(items.last?.secondaryUnitText)
        XCTAssertEqual(items.last?.accessibilityText, "Local history, Total 25, Main thread 12")
    }

    func test_refreshModulePresentationsPublishesVisibleSectionsInDashboardOrder() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(TokenHistoryDocument.empty).write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.showRemainingQuotaCard = false
        settings.showMessageActivityCard = true
        settings.showThirtyDayChartCard = true
        settings.showUsageOverviewCard = false
        settings.showUsageOverviewNumericCard = true
        settings.showCodeReviewCard = true
        settings.showCreditsCard = true
        settings.setDashboardModuleOrder([
            .messageActivity,
            .codeReview,
            .credits,
            .usageOverviewNumeric,
            .lastThirtyDays,
        ])

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        var publishedSections: [TokenMenuContentSection] = []
        store.onSectionPresentationPublished = { section in
            publishedSections.append(section)
        }

        await store.refreshModulePresentationsForCurrentState()

        XCTAssertEqual(
            publishedSections,
            [
                .messageActivity,
                .summaryPair(first: .codeReview, second: .credits),
                .usageOverviewNumeric,
                .thirtyDayChart,
            ])
    }

    func test_rawHistoryMutationKeepsPreviousNumericPresentationUntilQueuedPublish() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayKey = DailyTokenStats.dayKey(for: today, calendar: calendar)

        let document = TokenHistoryDocument(
            sessions: [:],
            days: [
                DailyTokenStats(
                    date: todayKey,
                    inputTokens: 20,
                    outputTokens: 5,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 25),
            ],
            lastRefreshAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: sandbox.fileURL, options: .atomic)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.showUsageOverviewNumericCard = true

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        XCTAssertEqual(store.usageOverviewNumericItemsPresentation.last?.primaryAmountText, "25")
        XCTAssertNil(store.usageOverviewNumericItemsPresentation.last?.primaryUnitText)

        store.days = [
            DailyTokenStats(
                date: todayKey,
                inputTokens: 70,
                outputTokens: 30,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 100),
        ]
        store.regularDays = [
            DailyTokenStats(
                date: todayKey,
                inputTokens: 25,
                outputTokens: 15,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 40),
        ]

        XCTAssertEqual(store.usageOverviewNumericItemsPresentation.last?.primaryAmountText, "25")
        XCTAssertEqual(store.usageOverviewNumericItemsPresentation.last?.secondaryAmountText, "0")

        await store.refreshModulePresentationsForCurrentState()

        XCTAssertEqual(store.usageOverviewNumericItemsPresentation.last?.primaryAmountText, "100")
        XCTAssertNil(store.usageOverviewNumericItemsPresentation.last?.primaryUnitText)
        XCTAssertEqual(store.usageOverviewNumericItemsPresentation.last?.secondaryAmountText, "40")
        XCTAssertNil(store.usageOverviewNumericItemsPresentation.last?.secondaryUnitText)
    }

    func test_refreshIncludesThreadSpawnSubagentTokensInUsageSummaries() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let currentHourStart = Self.currentHourStart()
        let regularTimestamp = currentHourStart.addingTimeInterval(10 * 60)
        let subagentTimestamp = currentHourStart.addingTimeInterval(20 * 60)
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionDirectory = Self.sessionDirectory(root: sessionRoot, date: currentHourStart)
        let regularFile = sessionDirectory.appendingPathComponent("regular.jsonl", isDirectory: false)
        let subagentFile = sessionDirectory.appendingPathComponent("subagent.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)

        try Self.regularSessionFixture(
            timestamp: regularTimestamp,
            sessionID: "session-regular",
            message: "main thread",
            inputTokens: 5,
            outputTokens: 3,
            totalTokens: 8).write(to: regularFile, atomically: true, encoding: .utf8)
        try Self.subagentSessionFixture(
            timestamp: subagentTimestamp,
            sessionID: "session-subagent",
            parentThreadID: "session-parent",
            message: "delegate this",
            inputTokens: 10,
            outputTokens: 3,
            totalTokens: 13).write(to: subagentFile, atomically: true, encoding: .utf8)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            codexQuotaProvider: FakeCodexQuotaProvider(),
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertEqual(store.today.totalTokens, 21)
        XCTAssertEqual(store.regularToday.totalTokens, 8)
        XCTAssertEqual(store.sevenDayTotal.totalTokens, 21)
        XCTAssertEqual(store.regularSevenDayTotal.totalTokens, 8)
        XCTAssertEqual(store.thirtyDayTotal.totalTokens, 21)
        XCTAssertEqual(store.regularThirtyDayTotal.totalTokens, 8)
        XCTAssertEqual(store.trailingFortyEightHours.reduce(0) { $0 + $1.totalTokens }, 21)
        XCTAssertEqual(store.trailingFortyEightHours.last?.totalTokens, 21)
        XCTAssertEqual(store.regularTrailingFortyEightHours.reduce(0) { $0 + $1.totalTokens }, 8)
        XCTAssertEqual(store.regularTrailingFortyEightHours.last?.totalTokens, 8)
        XCTAssertEqual(store.todayOutboundMessages.sentMessages, 1)
        XCTAssertEqual(store.outboundMessageDays.first?.sentMessages, 1)
    }

    func test_refreshUsesTotalTokenUsageDeltaInUsageSummaries() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let currentHourStart = Self.currentHourStart()
        let regularTimestamp = currentHourStart.addingTimeInterval(10 * 60)
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionDirectory = Self.sessionDirectory(root: sessionRoot, date: currentHourStart)
        let regularFile = sessionDirectory.appendingPathComponent(
            "regular-total-usage-delta.jsonl",
            isDirectory: false)
        try FileManager.default.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)

        let regularFixture = [
            Self.sessionMetaLine(timestamp: regularTimestamp, sessionID: "session-regular-delta"),
            Self.userMessageLine(timestamp: regularTimestamp.addingTimeInterval(0.1), message: "main thread"),
            Self.tokenCountLine(
                timestamp: regularTimestamp.addingTimeInterval(0.2),
                inputTokens: 10,
                outputTokens: 3,
                totalTokens: 13,
                totalUsageInputTokens: 10,
                totalUsageOutputTokens: 3,
                totalUsageCachedInputTokens: 5,
                totalUsageReasoningOutputTokens: 1),
            Self.tokenCountLine(
                timestamp: regularTimestamp.addingTimeInterval(0.3),
                inputTokens: 3,
                outputTokens: 2,
                totalTokens: 5,
                totalUsageInputTokens: 13,
                totalUsageOutputTokens: 5,
                totalUsageCachedInputTokens: 6,
                totalUsageReasoningOutputTokens: 2),
            Self.tokenCountLine(
                timestamp: regularTimestamp.addingTimeInterval(0.4),
                inputTokens: 3,
                outputTokens: 2,
                totalTokens: 5,
                totalUsageInputTokens: 13,
                totalUsageOutputTokens: 5,
                totalUsageCachedInputTokens: 6,
                totalUsageReasoningOutputTokens: 2),
        ].joined(separator: "\n")
        try regularFixture.write(to: regularFile, atomically: true, encoding: .utf8)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            codexQuotaProvider: FakeCodexQuotaProvider(),
            dashboardProvider: FakeOpenAIDashboardProvider(),
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertEqual(store.today.totalTokens, 18)
        XCTAssertEqual(store.sevenDayTotal.totalTokens, 18)
        XCTAssertEqual(store.thirtyDayTotal.totalTokens, 18)
        XCTAssertEqual(store.trailingFortyEightHours.reduce(0) { $0 + $1.totalTokens }, 18)
        XCTAssertEqual(store.trailingFortyEightHours.last?.totalTokens, 18)
        XCTAssertEqual(store.todayOutboundMessages.sentMessages, 1)
    }

    func test_failedDashboardRefreshKeepsCachedSnapshotMarkedStale() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let cachedDashboard = Self.makeDashboardSnapshot(updatedAt: Date(timeIntervalSince1970: 1_730_000_000))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.cachedDashboard = OpenAIDashboardCache(
            accountEmail: "person@example.com",
            snapshot: cachedDashboard)
        dashboardProvider.refreshError = OpenAIDashboardFetcher.FetchError.loginRequired

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertEqual(store.openAIDashboard, cachedDashboard)
        XCTAssertTrue(store.openAIDashboardIsStale)
        XCTAssertEqual(store.lastOpenAIDashboardError, settings.strings.quotaNeedsLoginMessage)
        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
    }

    func test_disabledOpenAIWebSkipsDashboardRefresh() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = false

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertTrue(dashboardProvider.refreshCalls.isEmpty)
        XCTAssertNil(store.openAIDashboard)
    }

    func test_defaultSettingsSkipDashboardRefreshUntilOptIn() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertFalse(settings.openAIWebAccessEnabled)
        XCTAssertFalse(settings.backgroundBrowserAutoImportEnabled)
        XCTAssertTrue(dashboardProvider.refreshCalls.isEmpty)
        XCTAssertNil(store.openAIDashboard)
    }

    func test_sparkToggleOffStopsOpenAIWebRefreshWhenNoOtherWebModulesNeedIt() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.showSparkQuotaCard = false
        settings.showCodeReviewCard = false
        settings.showCreditsCard = false
        settings.showUsageBreakdownCard = false
        settings.showCreditsHistoryCard = false

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertFalse(store.shouldRefreshOpenAIWebData)
        XCTAssertTrue(dashboardProvider.refreshCalls.isEmpty)
        XCTAssertNil(store.openAIDashboard)
    }

    func test_sparkQuotaEnabledDoesNotTriggerDashboardRefreshWhenStructuredQuotaExists() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.showSparkQuotaCard = true
        settings.showCodeReviewCard = false
        settings.showCreditsCard = false
        settings.showUsageBreakdownCard = false
        settings.showCreditsHistoryCard = false

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        let codexQuotaProvider = FakeCodexQuotaProvider(snapshot: Self.makeCodexQuotaSnapshot(
            updatedAt: Date(),
            sparkPrimary: RateWindow(
                usedPercent: 1,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            sparkSecondary: RateWindow(
                usedPercent: 13,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: nil)))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            codexQuotaProvider: codexQuotaProvider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertFalse(store.shouldRefreshOpenAIWebData)
        XCTAssertFalse(store.shouldRefreshSparkQuotaFallback)
        XCTAssertEqual(dashboardProvider.refreshCalls, [])
        XCTAssertEqual(store.sparkPrimaryQuotaWindow?.usedPercent, 1, accuracy: 0.01)
        XCTAssertEqual(store.sparkSecondaryQuotaWindow?.usedPercent, 13, accuracy: 0.01)
        XCTAssertFalse(store.sparkQuotaUsesOpenAIWebFallback)
        XCTAssertFalse(store.sparkQuotaIsStale)
    }

    func test_sparkQuotaFallsBackToDashboardWhenStructuredQuotaIsMissing() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.showSparkQuotaCard = true
        settings.showCodeReviewCard = false
        settings.showCreditsCard = false
        settings.showUsageBreakdownCard = false
        settings.showCreditsHistoryCard = false

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        let dashboardSnapshot = OpenAIDashboardSnapshot(
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
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: dashboardSnapshot,
            targetEmail: "person@example.com",
            cookieImportResult: nil,
            usedCache: false)
        let store = UsageStore(
            settings: settings,
            provider: provider,
            codexQuotaProvider: FakeCodexQuotaProvider(snapshot: Self.makeCodexQuotaSnapshot(updatedAt: Date())),
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertFalse(store.shouldRefreshOpenAIWebData)
        XCTAssertTrue(store.shouldRefreshSparkQuotaFallback)
        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
        XCTAssertEqual(store.sparkPrimaryQuotaWindow?.usedPercent, 22, accuracy: 0.01)
        XCTAssertEqual(store.sparkSecondaryQuotaWindow?.usedPercent, 18, accuracy: 0.01)
        XCTAssertTrue(store.sparkQuotaUsesOpenAIWebFallback)
    }

    func test_otherOpenAIWebModulesKeepRefreshRunningWhenSparkToggleIsOff() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.showSparkQuotaCard = false
        settings.showUsageBreakdownCard = true

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: Self.makeDashboardSnapshot(updatedAt: Date()),
            targetEmail: "person@example.com",
            cookieImportResult: nil,
            usedCache: false)

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertTrue(store.shouldRefreshOpenAIWebData)
        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
    }

    func test_deferredBrowserImportShowsManualRefreshMessageWithoutLoginFlags() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        settings.openAIWebAccessEnabled = true
        settings.codexCookieSource = .auto
        settings.backgroundBrowserAutoImportEnabled = false
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshError = OpenAIDashboardRefreshError.browserImportDeferredUntilUserAction

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertNil(store.openAIDashboard)
        XCTAssertFalse(store.openAIDashboardIsStale)
        XCTAssertEqual(
            store.openAIDashboardDisplayState,
            .cachedNeedsManualRefresh(message: settings.strings.openAIWebAutoImportDeferredMessage))
        XCTAssertNil(store.lastOpenAIDashboardError)
        XCTAssertEqual(store.openAIDashboardCookieImportStatus, settings.strings.openAIWebAutoImportDeferredMessage)
        XCTAssertFalse(store.openAIDashboardRequiresLogin)
        XCTAssertFalse(store.openAIDashboardPermissionDenied)
        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
    }

    func test_deferredBrowserImportKeepsCachedSnapshotMarkedStale() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let cachedDashboard = Self.makeDashboardSnapshot(updatedAt: Date(timeIntervalSince1970: 1_730_000_000))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.cachedDashboard = OpenAIDashboardCache(
            accountEmail: "person@example.com",
            snapshot: cachedDashboard)
        dashboardProvider.refreshError = OpenAIDashboardRefreshError.browserImportDeferredUntilUserAction

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.codexCookieSource = .auto
        settings.backgroundBrowserAutoImportEnabled = false
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertEqual(store.openAIDashboard, cachedDashboard)
        XCTAssertTrue(store.openAIDashboardIsStale)
        XCTAssertEqual(
            store.openAIDashboardDisplayState,
            .cachedNeedsManualRefresh(message: settings.strings.openAIWebAutoImportDeferredMessage))
        XCTAssertNil(store.lastOpenAIDashboardError)
        XCTAssertEqual(store.openAIDashboardCookieImportStatus, settings.strings.openAIWebAutoImportDeferredMessage)
        XCTAssertFalse(store.openAIDashboardRequiresLogin)
        XCTAssertFalse(store.openAIDashboardPermissionDenied)
        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
    }

    func test_manualCookieModeDefersToManualRefreshWithoutShowingQuotaError() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let cachedDashboard = Self.makeDashboardSnapshot(updatedAt: Date(timeIntervalSince1970: 1_730_000_500))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.cachedDashboard = OpenAIDashboardCache(
            accountEmail: "person@example.com",
            snapshot: cachedDashboard)
        dashboardProvider.refreshError = OpenAIDashboardRefreshError.manualRefreshRequiredUntilUserAction

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        settings.openAIWebAccessEnabled = true
        settings.codexCookieSource = .manual
        settings.codexCookieHeader = "oai-did=example;"
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertEqual(store.openAIDashboard, cachedDashboard)
        XCTAssertTrue(store.openAIDashboardIsStale)
        XCTAssertEqual(
            store.openAIDashboardDisplayState,
            .cachedNeedsManualRefresh(message: settings.strings.manualDashboardRefreshRequiredMessage))
        XCTAssertNil(store.lastOpenAIDashboardError)
        XCTAssertEqual(store.openAIDashboardCookieImportStatus, settings.strings.manualDashboardRefreshRequiredMessage)
        XCTAssertNil(store.openAIDashboardQuotaCardErrorMessage)
    }

    func test_backgroundRefreshPassesAutoImportSettingToDashboardProvider() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.codexCookieSource = .auto
        settings.backgroundBrowserAutoImportEnabled = true
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: Self.makeDashboardSnapshot(updatedAt: Date()),
            targetEmail: "person@example.com",
            cookieImportResult: nil,
            usedCache: false)

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
        XCTAssertEqual(
            dashboardProvider.refreshSettings.map(\.backgroundBrowserAutoImportEnabled),
            [true])
        XCTAssertNil(store.lastOpenAIDashboardError)
    }

    func test_forceRefreshOpenAIDashboardFromSafariUsesSafariModeAndSkipsHistoryRefresh() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.codexCookieSource = .auto
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: Self.makeDashboardSnapshot(updatedAt: Date()),
            targetEmail: "person@example.com",
            cookieImportResult: OpenAIDashboardBrowserCookieImporter.ImportResult(
                sourceLabel: "Safari",
                cookieCount: 3,
                signedInEmail: "person@example.com",
                matchesCodexEmail: true),
            usedCache: false)

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.forceRefreshOpenAIDashboardFromSafari()

        XCTAssertEqual(dashboardProvider.refreshCalls, [true])
        XCTAssertEqual(dashboardProvider.refreshSettings.map(\.cookieSource), [.safari])
        XCTAssertEqual(store.openAIDashboardCookieImportStatus?.contains("Safari"), true)
    }

    func test_forceRefreshOpenAIDashboardFromSafariBypassesSparkFeatureGate() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.showSparkQuotaCard = false
        settings.showCodeReviewCard = false
        settings.showCreditsCard = false
        settings.showUsageBreakdownCard = false
        settings.showCreditsHistoryCard = false

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: Self.makeDashboardSnapshot(updatedAt: Date()),
            targetEmail: "person@example.com",
            cookieImportResult: OpenAIDashboardBrowserCookieImporter.ImportResult(
                sourceLabel: "Safari",
                cookieCount: 2,
                signedInEmail: "person@example.com",
                matchesCodexEmail: true),
            usedCache: false)

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.forceRefreshOpenAIDashboardFromSafari()

        XCTAssertFalse(store.shouldRefreshOpenAIWebData)
        XCTAssertEqual(dashboardProvider.refreshCalls, [true])
        XCTAssertEqual(dashboardProvider.refreshSettings.map(\.cookieSource), [.safari])
    }

    func test_manualCookieModeBackgroundRefreshStillRuns() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        settings.openAIWebAccessEnabled = true
        settings.codexCookieSource = .manual
        settings.codexCookieHeader = "oai-did=example; __Secure-next-auth.session-token=example;"

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: Self.makeDashboardSnapshot(updatedAt: Date()),
            targetEmail: "person@example.com",
            cookieImportResult: nil,
            usedCache: false)

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: false)

        XCTAssertNotNil(store.openAIDashboard)
        XCTAssertEqual(dashboardProvider.refreshCalls, [false])
    }

    func test_successfulDashboardRefreshPopulatesStatus() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshResult = OpenAIDashboardRefreshResult(
            snapshot: Self.makeDashboardSnapshot(updatedAt: Date()),
            targetEmail: "person@example.com",
            cookieImportResult: OpenAIDashboardBrowserCookieImporter.ImportResult(
                sourceLabel: "Safari",
                cookieCount: 5,
                signedInEmail: "person@example.com",
                matchesCodexEmail: true),
            usedCache: false)

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: true)

        XCTAssertNotNil(store.openAIDashboard)
        XCTAssertEqual(dashboardProvider.refreshCalls, [true])
        XCTAssertTrue(store.openAIDashboardCookieImportStatus?.contains("Safari") == true)
    }

    func test_browserAccessDeniedMarksPermissionState() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["zh-Hans"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.refreshError = OpenAIDashboardBrowserCookieImporter.ImportError.browserAccessDenied(
            details: "Safari cookie file exists but is not readable.")

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        await store.refresh(forceDashboard: true)

        XCTAssertTrue(store.openAIDashboardPermissionDenied)
        XCTAssertEqual(store.lastOpenAIDashboardError, settings.strings.browserAccessDeniedMessage)
        XCTAssertTrue(store.openAIDashboardCookieImportStatus?.contains("Safari") == true)
    }

    func test_initializesAccountPlanFallbackFromDashboardProvider() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sandbox = try UsageStoreSandbox()
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let dashboardProvider = FakeOpenAIDashboardProvider()
        dashboardProvider.accountInfo = CodexAccountInfo(email: "person@example.com", plan: "pro")

        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: dashboardProvider,
            startupRefresh: false)

        XCTAssertEqual(store.openAIAccountPlanFallback, "Pro")
    }

    private static func makeDashboardSnapshot(
        updatedAt: Date,
        primaryLimit: RateWindow = RateWindow(
            usedPercent: 44,
            windowMinutes: 5 * 60,
            resetsAt: nil,
            resetDescription: nil),
        secondaryLimit: RateWindow? = RateWindow(
            usedPercent: 12,
            windowMinutes: 7 * 24 * 60,
            resetsAt: nil,
            resetDescription: nil))
        -> OpenAIDashboardSnapshot
    {
        OpenAIDashboardSnapshot(
            signedInEmail: "person@example.com",
            codeReviewRemainingPercent: 61,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: primaryLimit,
            secondaryLimit: secondaryLimit,
            creditsRemaining: 22,
            accountPlan: "Plus",
            updatedAt: updatedAt)
    }

    private static func makeCodexQuotaSnapshot(
        updatedAt: Date,
        primaryLimit: RateWindow = RateWindow(
            usedPercent: 44,
            windowMinutes: 5 * 60,
            resetsAt: nil,
            resetDescription: nil),
        secondaryLimit: RateWindow? = RateWindow(
            usedPercent: 12,
            windowMinutes: 7 * 24 * 60,
            resetsAt: nil,
            resetDescription: nil),
        sparkPrimary: RateWindow? = nil,
        sparkSecondary: RateWindow? = nil)
        -> CodexQuotaSnapshot
    {
        CodexQuotaSnapshot(
            primary: primaryLimit,
            secondary: secondaryLimit,
            sparkPrimary: sparkPrimary,
            sparkSecondary: sparkSecondary,
            updatedAt: updatedAt,
            accountEmail: "person@example.com",
            accountPlan: "Pro")
    }

    private static func currentHourStart() -> Date {
        Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()
    }

    private static func sessionDirectory(root: URL, date: Date) -> URL {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return root
            .appendingPathComponent(String(format: "%04d", year), isDirectory: true)
            .appendingPathComponent(String(format: "%02d", month), isDirectory: true)
            .appendingPathComponent(String(format: "%02d", day), isDirectory: true)
    }

    private static func regularSessionFixture(
        timestamp: Date,
        sessionID: String,
        message: String,
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int) -> String
    {
        [
            self.sessionMetaLine(timestamp: timestamp, sessionID: sessionID),
            self.userMessageLine(timestamp: timestamp.addingTimeInterval(0.1), message: message),
            self.tokenCountLine(
                timestamp: timestamp.addingTimeInterval(0.2),
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                totalTokens: totalTokens),
        ].joined(separator: "\n")
    }

    private static func subagentSessionFixture(
        timestamp: Date,
        sessionID: String,
        parentThreadID: String,
        message: String,
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int) -> String
    {
        let sourceJSON =
            #"{"subagent":{"thread_spawn":{"parent_thread_id":"\#(parentThreadID)","depth":1}}}"#
        return [
            self.sessionMetaLine(timestamp: timestamp, sessionID: sessionID, sourceJSON: sourceJSON),
            self.userMessageLine(timestamp: timestamp.addingTimeInterval(0.1), message: message),
            self.tokenCountLine(
                timestamp: timestamp.addingTimeInterval(0.2),
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                totalTokens: totalTokens),
        ].joined(separator: "\n")
    }

    private static func sessionMetaLine(timestamp: Date, sessionID: String, sourceJSON: String? = nil) -> String {
        let sourceField = if let sourceJSON {
            ",\"source\":\(sourceJSON)"
        } else {
            ""
        }

        return "{"
            + "\"timestamp\":\"\(self.isoTimestamp(timestamp))\","
            + "\"type\":\"session_meta\","
            + "\"payload\":{\"id\":\"\(sessionID)\"\(sourceField)}}"
    }

    private static func userMessageLine(timestamp: Date, message: String) -> String {
        "{"
            + "\"timestamp\":\"\(self.isoTimestamp(timestamp))\","
            + "\"type\":\"event_msg\","
            + "\"payload\":{\"type\":\"user_message\",\"message\":\"\(message)\"}}"
    }

    private static func tokenCountLine(
        timestamp: Date,
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int,
        totalUsageInputTokens: Int? = nil,
        totalUsageOutputTokens: Int? = nil,
        totalUsageCachedInputTokens: Int? = nil,
        totalUsageReasoningOutputTokens: Int? = nil) -> String
    {
        let totalUsageField = if totalUsageInputTokens != nil
            || totalUsageOutputTokens != nil
            || totalUsageCachedInputTokens != nil
            || totalUsageReasoningOutputTokens != nil
        {
            ",\"total_token_usage\":{"
                + "\"input_tokens\":\(totalUsageInputTokens ?? inputTokens),"
                + "\"output_tokens\":\(totalUsageOutputTokens ?? outputTokens),"
                + "\"cached_input_tokens\":\(totalUsageCachedInputTokens ?? 0),"
                + "\"reasoning_output_tokens\":\(totalUsageReasoningOutputTokens ?? 0),"
                + "\"total_tokens\":\((totalUsageInputTokens ?? inputTokens) + (totalUsageOutputTokens ?? outputTokens))"
                + "}"
        } else {
            ""
        }

        "{"
            + "\"timestamp\":\"\(self.isoTimestamp(timestamp))\","
            + "\"type\":\"event_msg\","
            + "\"payload\":{\"type\":\"token_count\",\"info\":{\"last_token_usage\":{"
            + "\"input_tokens\":\(inputTokens),"
            + "\"output_tokens\":\(outputTokens),"
            + "\"cached_input_tokens\":0,"
            + "\"reasoning_output_tokens\":0,"
            + "\"total_tokens\":\(totalTokens)"
            + "}"
            + totalUsageField
            + "}}}"
    }

    private static func isoTimestamp(_ date: Date) -> String {
        self.iso8601Formatter.string(from: date)
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private struct UsageStoreSandbox {
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
private final class FakeOpenAIDashboardProvider: OpenAIDashboardProviding {
    var cachedDashboard: OpenAIDashboardCache?
    var refreshResult: OpenAIDashboardRefreshResult?
    var refreshError: Error?
    var refreshCalls: [Bool] = []
    var refreshSettings: [OpenAIDashboardSettings] = []
    var accountInfo = CodexAccountInfo(email: "person@example.com", plan: "Plus")

    func loadCachedDashboard() throws -> OpenAIDashboardCache? {
        self.cachedDashboard
    }

    func loadAccountInfo() -> CodexAccountInfo {
        self.accountInfo
    }

    func refresh(
        settings: OpenAIDashboardSettings,
        force: Bool,
        logger _: ((String) -> Void)?) async throws -> OpenAIDashboardRefreshResult
    {
        self.refreshCalls.append(force)
        self.refreshSettings.append(settings)
        if let refreshError = self.refreshError {
            throw refreshError
        }
        return try XCTUnwrap(self.refreshResult)
    }
}

private struct FakeCodexQuotaProvider: CodexQuotaProviding {
    var snapshot: CodexQuotaSnapshot?
    var error: Error?

    init(snapshot: CodexQuotaSnapshot? = nil, error: Error? = nil) {
        self.snapshot = snapshot
        self.error = error
    }

    func loadQuotaSnapshot() async throws -> CodexQuotaSnapshot {
        if let error = self.error {
            throw error
        }

        guard let snapshot = self.snapshot else {
            throw FakeCodexQuotaProviderError.unavailable
        }

        return snapshot
    }
}

private enum FakeCodexQuotaProviderError: Error {
    case unavailable
}

@MainActor
private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    var enabled = false

    func isEnabled() -> Bool {
        self.enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        self.enabled = enabled
    }
}

actor FakeTokenRateMonitor: CodexLiveTokenRateMonitoring {
    private let samples: [TokenSpeedSample]
    private var sampleIndex = 0
    private(set) var resetCallCount = 0

    init(samples: [TokenSpeedSample]) {
        self.samples = samples
    }

    func sample() async -> TokenSpeedSample {
        guard self.sampleIndex < self.samples.count else {
            return TokenSpeedSample(timestamp: Date(), tokens: 0)
        }

        let value = self.samples[self.sampleIndex]
        self.sampleIndex += 1
        return value
    }

    func reset() async {
        self.resetCallCount += 1
        self.sampleIndex = 0
    }
}
