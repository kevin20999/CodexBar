import CodexBarCore
import Foundation
import XCTest
@testable import CodexDailyKit

@MainActor
final class TokenDailyBoardStoreTests: XCTestCase {
    func test_initMarksMissingWhenCacheFileDoesNotExist() {
        let fileURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: fileURL),
            autoStartMonitoring: false)

        XCTAssertEqual(store.cacheState, .missing)
        XCTAssertTrue(store.days.isEmpty)
        XCTAssertNil(store.lastRefreshAt)
    }

    func test_initLoadsCachedHistoryDocument() throws {
        let fileURL = self.temporaryFileURL()
        let historyStore = TokenHistoryStore(fileURL: fileURL)
        let refreshDate = Date(timeIntervalSince1970: 1_744_096_000)

        _ = try historyStore.merge(refreshResult: TokenRefreshResult(
            sessions: [
                "regular-session": SessionUsageSnapshot(
                    sessionID: "regular-session",
                    sessionOriginKind: .regular,
                    sourceFile: "/tmp/regular.json",
                    sourceFileSize: nil,
                    sourceFileModificationTime: refreshDate,
                    lastEventAt: refreshDate,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: "2026-04-08",
                            inputTokens: 4,
                            outputTokens: 5,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 9),
                    ]),
                "spawned-session": SessionUsageSnapshot(
                    sessionID: "spawned-session",
                    sessionOriginKind: .subagentThreadSpawn,
                    sourceFile: "/tmp/spawned.json",
                    sourceFileSize: nil,
                    sourceFileModificationTime: refreshDate,
                    lastEventAt: refreshDate,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: "2026-04-08",
                            inputTokens: 100,
                            outputTokens: 100,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 200),
                    ]),
            ],
            days: [
                DailyTokenStats(
                    date: "2026-04-08",
                    inputTokens: 10,
                    outputTokens: 20,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 30),
            ],
            hours: [],
            fiveMinuteBuckets: [
                FiveMinuteTokenStats(
                    bucketStart: refreshDate,
                    inputTokens: 10,
                    outputTokens: 20,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 30),
            ],
            outboundMessageDays: [
                DailyOutboundMessageStats(
                    date: "2026-04-08",
                    sentCharacters: 42,
                    sentMessages: 2),
            ],
            refreshedAt: refreshDate,
            scannedFileCount: 1,
            reusedSessionCount: 0,
            errors: []))

        let store = TokenDailyBoardStore(historyStore: historyStore, autoStartMonitoring: false)

        XCTAssertEqual(store.cacheState, .ready)
        XCTAssertEqual(store.days.count, 1)
        XCTAssertEqual(store.regularDays.count, 1)
        XCTAssertEqual(store.regularDays.first?.totalTokens, 9)
        XCTAssertEqual(store.fiveMinuteBuckets.count, 1)
        XCTAssertEqual(store.outboundMessageDays.count, 1)
        XCTAssertEqual(store.lastRefreshAt, refreshDate)
    }

    func test_initImportsLegacyCacheOnceIntoCodexDailyPath() throws {
        let legacyURL = self.temporaryFileURL()
        let destinationURL = self.temporaryFileURL()
        let refreshDate = Date(timeIntervalSince1970: 1_744_096_000)
        let legacyStore = TokenHistoryStore(fileURL: legacyURL)

        _ = try legacyStore.merge(refreshResult: TokenRefreshResult(
            sessions: [:],
            days: [
                DailyTokenStats(
                    date: "2026-04-08",
                    inputTokens: 10,
                    outputTokens: 20,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 30),
            ],
            hours: [],
            fiveMinuteBuckets: [],
            outboundMessageDays: [],
            refreshedAt: refreshDate,
            scannedFileCount: 1,
            reusedSessionCount: 0,
            errors: []))

        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: destinationURL),
            migrationSourceFileURLs: [legacyURL],
            autoStartMonitoring: false)

        XCTAssertEqual(store.cacheState, .ready)
        XCTAssertEqual(store.days.first?.totalTokens, 30)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
    }

    func test_realtimeHistoryPathsStayInCodexDailySupportDirectory() {
        XCTAssertTrue(CodexDailyAppIdentity.tokenSpeedHistoryFileURL.path.contains("/Application Support/CodexDaily/"))
        XCTAssertTrue(CodexDailyAppIdentity.instructionEventHistoryFileURL.path
            .contains("/Application Support/CodexDaily/"))
        XCTAssertTrue(CodexDailyAppIdentity.narrativeUserCatalogFileURL.path
            .contains("/Application Support/CodexDaily/"))
        XCTAssertTrue(CodexDailyAppIdentity.avatarCustomizationFileURL.path
            .contains("/Application Support/CodexDaily/"))
        XCTAssertTrue(CodexDailyAppIdentity.avatarAssetsDirectoryURL.path
            .contains("/Application Support/CodexDaily/"))
        XCTAssertFalse(CodexDailyAppIdentity.tokenSpeedHistoryFileURL.path.contains("CodexTokenBar"))
        XCTAssertFalse(CodexDailyAppIdentity.instructionEventHistoryFileURL.path.contains("CodexTokenBar"))
        XCTAssertFalse(CodexDailyAppIdentity.narrativeUserCatalogFileURL.path.contains("CodexTokenBar"))
        XCTAssertFalse(CodexDailyAppIdentity.avatarCustomizationFileURL.path.contains("CodexTokenBar"))
        XCTAssertFalse(CodexDailyAppIdentity.avatarAssetsDirectoryURL.path.contains("CodexTokenBar"))
    }

    func test_settingsDefaultRefreshFrequencyMatchesTokenBar() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertEqual(settings.refreshFrequency, .tenSeconds)
    }

    func test_settingsMigrateLegacyRefreshIntervalToClosestCadence() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        defaults?.set(300, forKey: "refreshIntervalSeconds")

        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertEqual(settings.refreshFrequency, .tenSeconds)
    }

    func test_settingsPersistNarrativeBodyFontScale() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        settings.narrativeBodyFontScale = 1.18

        let reloaded = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertEqual(reloaded.narrativeBodyFontScale, 1.18, accuracy: 0.001)
    }

    func test_settingsClampNarrativeBodyFontScaleIntoAllowedRange() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        settings.narrativeBodyFontScale = 3.0
        XCTAssertEqual(settings.narrativeBodyFontScale, 1.3, accuracy: 0.001)

        settings.narrativeBodyFontScale = 0.1
        XCTAssertEqual(settings.narrativeBodyFontScale, 0.7, accuracy: 0.001)
    }

    func test_settingsPersistBoardDisplayMode() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        settings.boardDisplayMode = .conversationAndToday

        let reloaded = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertEqual(reloaded.boardDisplayMode, .conversationAndToday)
    }

    func test_settingsDefaultConversationOnlyPinnedIsFalse() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertFalse(settings.isConversationOnlyPinned)
    }

    func test_settingsDefaultTitlebarControlsCollapsedIsTrue() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertTrue(settings.titlebarControlsCollapsed)
    }

    func test_settingsDefaultWindowOriginIsNil() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertNil(settings.windowOrigin)
    }

    func test_settingsDefaultDebugPanelOriginIsNil() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertNil(settings.debugPanelOrigin)
    }

    func test_conversationOnlyWindowHoverStateIsRuntimeOnly() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let store = TokenDailyBoardStore(settings: settings, autoStartMonitoring: false, autoStartRefresh: false)

        XCTAssertTrue(store.isConversationOnlyWindowHovered)

        store.setConversationOnlyWindowHovered(false)
        XCTAssertFalse(store.isConversationOnlyWindowHovered)

        let reloadedSettings = CodexDailySettingsStore(userDefaults: defaults)
        let reloadedStore = TokenDailyBoardStore(
            settings: reloadedSettings,
            autoStartMonitoring: false,
            autoStartRefresh: false)

        XCTAssertTrue(reloadedStore.isConversationOnlyWindowHovered)
    }

    func test_settingsDefaultConversationOnlyDebugTuningUsesDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)

        XCTAssertEqual(settings.conversationOnlyDebugTuning.contentOffset.width, -101, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.contentOffset.height, -7, accuracy: 0.001)
        XCTAssertEqual(
            settings.conversationOnlyDebugTuning.windowWidth,
            TokenDailyBoardConversationOnlyLayoutRules.defaultCompactWindowSize.width,
            accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.windowGlassOpacity, 0.95, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.windowGlassBlur, 0, accuracy: 0.001)
        XCTAssertFalse(settings.conversationOnlyDebugTuning.enablesPreNarrativeWindowPulse)
        XCTAssertTrue(settings.conversationOnlyDebugTuning.enablesAvatarReplacementAnimation)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.animationPreset, .cinematic)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.pulseDurationScale, 1, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.avatarIntensityScale, 1, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.bodyTypewriterSpeedScale, 1, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.metadataTypewriterSpeedScale, 1, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.avatarSize, 92, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.bodyFontSize, 16, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.textColumnOffset.width, 3, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.textColumnOffset.height, 16, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.textColumnWidth, 284, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.bodyLineSpacing, 12, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.metadataFontSize, 10.5, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning.metadataOpacity, 0.65, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning, TokenDailyBoardConversationOnlyDebugRules.defaultTuning)
    }

    func test_storePersistsConversationOnlyDebugTuningAcrossReload() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let historyURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setConversationOnlyDebugTuning(
            TokenDailyBoardConversationOnlyDebugTuning(
                contentOffset: CGSize(width: 18, height: -12),
                windowWidth: 812,
                windowGlassOpacity: 0.55,
                windowGlassBlur: 13,
                enablesPreNarrativeWindowPulse: true,
                enablesAvatarReplacementAnimation: false,
                animationPreset: .aggressive,
                pulseDurationScale: 1.35,
                avatarIntensityScale: 1.25,
                bodyTypewriterSpeedScale: 1.15,
                metadataTypewriterSpeedScale: 1.05,
                avatarSize: 64,
                bodyFontSize: 29,
                textColumnOffset: CGSize(width: -11, height: 7),
                textColumnWidth: 410,
                bodyLineSpacing: 5,
                metadataFontSize: 16,
                metadataOpacity: 0.45))

        let reloadedSettings = CodexDailySettingsStore(userDefaults: defaults)
        let reloadedStore = TokenDailyBoardStore(
            settings: reloadedSettings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        XCTAssertEqual(reloadedSettings.conversationOnlyDebugTuning, store.conversationOnlyDebugTuning)
        XCTAssertEqual(reloadedStore.conversationOnlyDebugTuning, store.conversationOnlyDebugTuning)
    }

    func test_storePersistsTitlebarControlsCollapsedAcrossReload() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let historyURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setTitlebarControlsCollapsed(false)

        let reloadedSettings = CodexDailySettingsStore(userDefaults: defaults)
        let reloadedStore = TokenDailyBoardStore(
            settings: reloadedSettings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        XCTAssertFalse(store.titlebarControlsCollapsed)
        XCTAssertFalse(reloadedSettings.titlebarControlsCollapsed)
        XCTAssertFalse(reloadedStore.titlebarControlsCollapsed)
    }

    func test_storePersistsConversationOnlyPinnedAcrossReload() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let historyURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setConversationOnlyPinned(true)

        let reloadedSettings = CodexDailySettingsStore(userDefaults: defaults)
        let reloadedStore = TokenDailyBoardStore(
            settings: reloadedSettings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        XCTAssertTrue(store.isConversationOnlyPinned)
        XCTAssertTrue(reloadedSettings.isConversationOnlyPinned)
        XCTAssertTrue(reloadedStore.isConversationOnlyPinned)
    }

    func test_storePersistsWindowOriginAcrossReload() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let historyURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setWindowOrigin(CGPoint(x: 321.4, y: 654.6))

        let reloadedSettings = CodexDailySettingsStore(userDefaults: defaults)
        let reloadedStore = TokenDailyBoardStore(
            settings: reloadedSettings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        XCTAssertEqual(store.windowOrigin?.x, 321, accuracy: 0.001)
        XCTAssertEqual(store.windowOrigin?.y, 655, accuracy: 0.001)
        XCTAssertEqual(reloadedSettings.windowOrigin?.x, 321, accuracy: 0.001)
        XCTAssertEqual(reloadedSettings.windowOrigin?.y, 655, accuracy: 0.001)
        XCTAssertEqual(reloadedStore.windowOrigin?.x, 321, accuracy: 0.001)
        XCTAssertEqual(reloadedStore.windowOrigin?.y, 655, accuracy: 0.001)
    }

    func test_storePersistsDebugPanelOriginAcrossReload() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let historyURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setDebugPanelOrigin(CGPoint(x: 777.4, y: 222.6))

        let reloadedSettings = CodexDailySettingsStore(userDefaults: defaults)
        let reloadedStore = TokenDailyBoardStore(
            settings: reloadedSettings,
            historyStore: TokenHistoryStore(fileURL: historyURL),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        XCTAssertEqual(reloadedSettings.debugPanelOrigin?.x, 777, accuracy: 0.001)
        XCTAssertEqual(reloadedSettings.debugPanelOrigin?.y, 223, accuracy: 0.001)
        XCTAssertEqual(reloadedStore.debugPanelOrigin?.x, 777, accuracy: 0.001)
        XCTAssertEqual(reloadedStore.debugPanelOrigin?.y, 223, accuracy: 0.001)

        reloadedStore.setDebugPanelOrigin(nil)

        let resetSettings = CodexDailySettingsStore(userDefaults: defaults)
        XCTAssertNil(resetSettings.debugPanelOrigin)
    }

    func test_storeClampsConversationOnlyDebugTuningIntoAllowedRange() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: self.temporaryFileURL()),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setConversationOnlyDebugTuning(
            TokenDailyBoardConversationOnlyDebugTuning(
                contentOffset: CGSize(width: 999, height: -999),
                windowWidth: 2000,
                windowGlassOpacity: 0.1,
                windowGlassBlur: 99,
                enablesPreNarrativeWindowPulse: true,
                enablesAvatarReplacementAnimation: false,
                animationPreset: .gentle,
                pulseDurationScale: 9,
                avatarIntensityScale: 9,
                bodyTypewriterSpeedScale: 9,
                metadataTypewriterSpeedScale: 9,
                avatarSize: 200,
                bodyFontSize: 80,
                textColumnOffset: CGSize(width: 999, height: -999),
                textColumnWidth: 999,
                bodyLineSpacing: 99,
                metadataFontSize: 99,
                metadataOpacity: 0))

        XCTAssertEqual(store.conversationOnlyDebugTuning.contentOffset.width, 120, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.contentOffset.height, -120, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.windowWidth, 960, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.windowGlassOpacity, 0.25, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.windowGlassBlur, 24, accuracy: 0.001)
        XCTAssertTrue(store.conversationOnlyDebugTuning.enablesPreNarrativeWindowPulse)
        XCTAssertFalse(store.conversationOnlyDebugTuning.enablesAvatarReplacementAnimation)
        XCTAssertEqual(store.conversationOnlyDebugTuning.animationPreset, .gentle)
        XCTAssertEqual(store.conversationOnlyDebugTuning.pulseDurationScale, 1.4, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.avatarIntensityScale, 1.5, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.bodyTypewriterSpeedScale, 1.5, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.metadataTypewriterSpeedScale, 1.5, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.avatarSize, 92, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.bodyFontSize, 32, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.textColumnOffset.width, 80, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.textColumnOffset.height, -40, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.textColumnWidth, 479, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.bodyLineSpacing, 12, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.metadataFontSize, 18, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.metadataOpacity, 0.2, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning, store.conversationOnlyDebugTuning)
    }

    func test_storeClampsConversationOnlyDebugTuningLowerBoundsIntoAllowedRange() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: self.temporaryFileURL()),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        store.setConversationOnlyDebugTuning(
            TokenDailyBoardConversationOnlyDebugTuning(
                contentOffset: CGSize(width: -999, height: 999),
                windowWidth: 1,
                windowGlassOpacity: 0.1,
                windowGlassBlur: -99,
                enablesPreNarrativeWindowPulse: true,
                enablesAvatarReplacementAnimation: false,
                animationPreset: .aggressive,
                pulseDurationScale: 0.1,
                avatarIntensityScale: 0.1,
                bodyTypewriterSpeedScale: 0.1,
                metadataTypewriterSpeedScale: 0.1,
                avatarSize: 1,
                bodyFontSize: 1,
                textColumnOffset: CGSize(width: -999, height: 999),
                textColumnWidth: 1,
                bodyLineSpacing: -99,
                metadataFontSize: 1,
                metadataOpacity: 0))

        XCTAssertEqual(store.conversationOnlyDebugTuning.contentOffset.width, -120, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.contentOffset.height, 120, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.windowWidth, 300, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.windowGlassOpacity, 0.25, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.windowGlassBlur, 0, accuracy: 0.001)
        XCTAssertTrue(store.conversationOnlyDebugTuning.enablesPreNarrativeWindowPulse)
        XCTAssertFalse(store.conversationOnlyDebugTuning.enablesAvatarReplacementAnimation)
        XCTAssertEqual(store.conversationOnlyDebugTuning.animationPreset, .aggressive)
        XCTAssertEqual(store.conversationOnlyDebugTuning.pulseDurationScale, 0.7, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.avatarIntensityScale, 0.6, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.bodyTypewriterSpeedScale, 0.7, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.metadataTypewriterSpeedScale, 0.7, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.avatarSize, 40, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.bodyFontSize, 16, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.textColumnOffset.width, -80, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.textColumnOffset.height, 40, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.textColumnWidth, 120, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.bodyLineSpacing, 0, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.metadataFontSize, 10, accuracy: 0.001)
        XCTAssertEqual(store.conversationOnlyDebugTuning.metadataOpacity, 0.2, accuracy: 0.001)
        XCTAssertEqual(settings.conversationOnlyDebugTuning, store.conversationOnlyDebugTuning)
    }

    func test_storeBuildsRealtimeNarrativeProjectionFromLoadedHistories() throws {
        let historyURL = self.temporaryFileURL()
        let tokenSpeedHistoryURL = self.temporaryFileURL()
        let instructionHistoryURL = self.temporaryFileURL()
        let tokenSpeedHistoryStore = TokenSpeedHistoryStore(fileURL: tokenSpeedHistoryURL)
        let instructionHistoryStore = InstructionEventHistoryStore(fileURL: instructionHistoryURL)
        let strings = TokenDailyBoardStrings()
        let start = Calendar.autoupdatingCurrent.startOfDay(for: Date()).addingTimeInterval(9 * 60 * 60)

        for index in 0..<3 {
            _ = try tokenSpeedHistoryStore.upsert(sample: TokenSpeedSample(
                timestamp: start.addingTimeInterval(TimeInterval(index * 60)),
                tokens: 120_000 + (index * 10000)))
        }
        _ = try instructionHistoryStore.upsert(samples: (0..<9).map { index in
            InstructionEventSample(
                id: "instruction-\(index + 1)",
                timestamp: start.addingTimeInterval(TimeInterval((index + 3) * 60)),
                sentCharacters: 40 + index)
        })

        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: historyURL),
            tokenSpeedHistoryStore: tokenSpeedHistoryStore,
            instructionEventHistoryStore: instructionHistoryStore,
            autoStartMonitoring: false,
            autoStartRefresh: false)

        let fullItems = TokenDailyBoardNarrativeBuilder.realtimePresentationSourceItems(
            tokenSpeedSamples: store.realtimeTokenSpeedSamples,
            instructionEventSamples: store.realtimeInstructionEvents,
            strings: strings)
        let expectedItems = Array(fullItems.suffix(TokenDailyBoardRealtimeNarrativeProjection.sourceItemLimit))
        let expectedSignature = expectedItems
            .map { item in
                let timestampComponent = item.displayTimestamp.map { String($0.timeIntervalSince1970) } ?? "none"
                return "\(item.signature):\(timestampComponent)"
            }
            .joined(separator: "|")

        XCTAssertEqual(store.realtimeNarrativeProjection.sourceItems, expectedItems)
        XCTAssertEqual(store.realtimeNarrativeProjection.sourceItems.count, 8)
        XCTAssertEqual(store.realtimeNarrativeProjection.sequenceSignature, expectedSignature)
        XCTAssertTrue(store.realtimeNarrativeProjection.hasEligibleIdleRealtimeActivity)
        XCTAssertEqual(
            store.realtimeNarrativeProjection.sourceItems.last?.sentence.metadataText,
            expectedItems.last?.sentence.metadataText)
    }

    func test_realtimeNarrativeProjectionMakeKeepsLatestEightItemsInOrder() {
        let strings = TokenDailyBoardStrings()
        let start = Calendar.autoupdatingCurrent.startOfDay(for: Date()).addingTimeInterval(10 * 60 * 60)
        let tokenSamples = [
            TokenSpeedSample(timestamp: start, tokens: 180_000),
            TokenSpeedSample(timestamp: start.addingTimeInterval(60), tokens: 220_000),
        ]
        let instructionSamples = (0..<10).map { index in
            InstructionEventSample(
                id: "instruction-\(index + 1)",
                timestamp: start.addingTimeInterval(TimeInterval((index + 2) * 60)),
                sentCharacters: 24 + index)
        }
        let fullItems = TokenDailyBoardNarrativeBuilder.realtimePresentationSourceItems(
            tokenSpeedSamples: tokenSamples,
            instructionEventSamples: instructionSamples,
            strings: strings)

        let projection = TokenDailyBoardRealtimeNarrativeProjection.make(
            tokenSpeedSamples: tokenSamples,
            instructionEventSamples: instructionSamples,
            strings: strings)
        let expectedItems = Array(fullItems.suffix(TokenDailyBoardRealtimeNarrativeProjection.sourceItemLimit))

        XCTAssertEqual(projection.sourceItems, expectedItems)
        XCTAssertEqual(projection.sourceItems.count, 8)
        XCTAssertEqual(projection.sourceItems.last?.sentence.metadataText, expectedItems.last?.sentence.metadataText)
        XCTAssertEqual(projection.sequenceSignature.split(separator: "|").count, 8)
    }

    func test_storeResetConversationOnlyDebugTuningReturnsToDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: self.temporaryFileURL()),
            autoStartMonitoring: false,
            autoStartRefresh: false)

        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.contentOffset = CGSize(width: 24, height: -9)
        tuning.windowWidth = 880
        tuning.windowGlassOpacity = 0.45
        tuning.windowGlassBlur = 10
        tuning.enablesPreNarrativeWindowPulse = true
        tuning.enablesAvatarReplacementAnimation = false
        tuning.avatarSize = 61
        tuning.bodyFontSize = 27
        tuning.textColumnOffset = CGSize(width: 5, height: -3)
        tuning.textColumnWidth = 402
        tuning.bodyLineSpacing = 4
        tuning.metadataFontSize = 15
        tuning.metadataOpacity = 0.55

        store.setConversationOnlyDebugTuning(tuning)
        store.resetConversationOnlyDebugTuning()

        XCTAssertEqual(store.conversationOnlyDebugTuning, TokenDailyBoardConversationOnlyDebugRules.defaultTuning)
        XCTAssertEqual(settings.conversationOnlyDebugTuning, TokenDailyBoardConversationOnlyDebugRules.defaultTuning)
    }

    func test_windowChromeVisibilityDefaultsToVisibleAndCanBeUpdated() {
        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: self.temporaryFileURL()),
            autoStartMonitoring: false)

        XCTAssertTrue(store.windowChromeVisible)

        store.setWindowChromeVisible(false)

        XCTAssertFalse(store.windowChromeVisible)
    }

    func test_upsertNarrativeUserEntryPersistsToCodexDailyCatalogFile() throws {
        let historyURL = self.temporaryFileURL()
        let narrativeURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: historyURL),
            narrativeUserCatalogStore: TokenDailyBoardNarrativeUserCatalogStore(fileURL: narrativeURL),
            autoStartMonitoring: false)

        let errorMessage = store.upsertNarrativeUserEntry(
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "entry-1",
                language: .zhHans,
                category: "嘴硬还想要",
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "你他妈又狠狠干了我 {throughputTokensCompact}。",
                enabled: true))

        XCTAssertNil(errorMessage)
        XCTAssertEqual(store.narrativeUserEntries.count, 1)

        let persistedEntries = try TokenDailyBoardNarrativeUserCatalogStore(fileURL: narrativeURL).load()
        XCTAssertEqual(persistedEntries.count, 1)
        XCTAssertEqual(persistedEntries.first?.text, "你他妈又狠狠干了我 {throughputTokensCompact}。")
    }

    func test_upsertNarrativeOverrideEntryPersistsOverrideTargetID() throws {
        let historyURL = self.temporaryFileURL()
        let narrativeURL = self.temporaryFileURL()
        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: historyURL),
            narrativeUserCatalogStore: TokenDailyBoardNarrativeUserCatalogStore(fileURL: narrativeURL),
            autoStartMonitoring: false)

        let errorMessage = store.upsertNarrativeUserEntry(
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "override-1",
                language: .zhHans,
                category: "覆盖内置",
                eventKind: .instructionPulse,
                instructionBand: .fortyToSeventyNine,
                tokenBand: nil,
                timeBand: nil,
                text: "你今天第 {instructionOrdinal} 次狠狠干我。",
                enabled: true,
                overrideTargetID: "bundled-instruction-1"))

        XCTAssertNil(errorMessage)

        let persistedEntries = try TokenDailyBoardNarrativeUserCatalogStore(fileURL: narrativeURL).load()
        XCTAssertEqual(persistedEntries.first?.overrideTargetID, "bundled-instruction-1")
    }

    func test_setNarrativeBodyFontScalePersistsClampedValueToSettings() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)
        let settings = CodexDailySettingsStore(userDefaults: defaults)
        let store = TokenDailyBoardStore(
            settings: settings,
            historyStore: TokenHistoryStore(fileURL: self.temporaryFileURL()),
            autoStartMonitoring: false)

        store.setNarrativeBodyFontScale(1.25)
        XCTAssertEqual(store.narrativeBodyFontScale, 1.25, accuracy: 0.001)
        XCTAssertEqual(settings.narrativeBodyFontScale, 1.25, accuracy: 0.001)

        store.setNarrativeBodyFontScale(5.0)
        XCTAssertEqual(store.narrativeBodyFontScale, 1.3, accuracy: 0.001)
        XCTAssertEqual(settings.narrativeBodyFontScale, 1.3, accuracy: 0.001)
    }

    func test_avatarCustomizationStoreProvidesTenResolvedSlotsByDefault() {
        let avatarStore = CodexDailyAvatarCustomizationStore(
            fileURL: self.temporaryFileURL(),
            assetsDirectoryURL: self.temporaryDirectoryURL())
        let slots = avatarStore.resolvedSlots(from: [])

        XCTAssertEqual(slots.count, 10)
        XCTAssertEqual(slots.first?.slot, .defaultAvatar)
        XCTAssertTrue(slots.allSatisfy { $0.image != nil })
        XCTAssertTrue(slots.allSatisfy { $0.conversationOnlyImage != nil })
        XCTAssertTrue(slots.allSatisfy { $0.isMirrored == TokenDailyBoardNarrativePresentationRules.avatarIsMirrored })
    }

    func test_avatarCustomizationPersistsImageOverrideAndPerSlotMirror() {
        let historyURL = self.temporaryFileURL()
        let customizationURL = self.temporaryFileURL()
        let assetsDirectoryURL = self.temporaryDirectoryURL()
        let avatarStore = CodexDailyAvatarCustomizationStore(
            fileURL: customizationURL,
            assetsDirectoryURL: assetsDirectoryURL)
        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: historyURL),
            avatarCustomizationStore: avatarStore,
            autoStartMonitoring: false)

        let sourceImageURL = self.repoRootURL()
            .appendingPathComponent("Sources/CodexDailyBoardShared/Resources/DailyBoardCodexAvatarVariant01.png")

        XCTAssertNil(store.replaceAvatarImage(for: .variant01, sourceURL: sourceImageURL))
        XCTAssertEqual(store.avatarResolvedSlots.count, 10)
        XCTAssertEqual(
            store.avatarResolvedSlots.first(where: { $0.slot == .variant01 })?.usesCustomImage,
            true)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: assetsDirectoryURL.appendingPathComponent("variant01.png").path))

        XCTAssertNil(store.setAvatarMirrored(false, for: .variant01))
        XCTAssertEqual(
            store.avatarResolvedSlots.first(where: { $0.slot == .variant01 })?.isMirrored,
            false)

        XCTAssertNil(store.restoreAvatarSlot(.variant01))
        let restoredSlot = store.avatarResolvedSlots.first(where: { $0.slot == .variant01 })
        XCTAssertEqual(restoredSlot?.usesCustomImage, false)
        XCTAssertEqual(restoredSlot?.isMirrored, TokenDailyBoardNarrativePresentationRules.avatarIsMirrored)
    }

    private func temporaryFileURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    private func temporaryDirectoryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func repoRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
